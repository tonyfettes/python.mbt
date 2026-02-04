# Memory Management Analysis Report: Python-MoonBit Binding

**Date:** 2026-02-01
**Author:** Claude Code Analysis
**Version:** 1.1 (Updated)

## Executive Summary

This report provides a comprehensive analysis of memory management issues in the Python-MoonBit binding (`python.mbt`). The binding had two categories of issues:

1. **Category 1:** Python C API reference counting bugs (borrowed/stolen references)
2. **Category 2:** MoonBit's RC system treating PyObjectRef as a MoonBit reference

**Both issues have been fixed:**

- Category 1: Fixed in commit `ffc7a7e` by adding proper `py_incref()` calls
- Category 2: Fixed by adding `#external` attribute to `PyObjectRef` type

The binding now correctly separates MoonBit's RC system from Python's RC system, and all tests pass with `PYTHONMALLOC=malloc` + AddressSanitizer.

---

## Table of Contents

1. [Background: Two Reference Counting Systems](#1-background-two-reference-counting-systems)
2. [Architecture Overview](#2-architecture-overview)
3. [Category 1: Python C API Reference Counting Bugs](#3-category-1-python-c-api-reference-counting-bugs)
4. [Category 2: MoonBit RC System Incompatibility](#4-category-2-moonbit-rc-system-incompatibility)
5. [Evidence: Generated C Code Analysis](#5-evidence-generated-c-code-analysis)
6. [Impact and Manifestation](#6-impact-and-manifestation)
7. [Recommendations for New Binding](#7-recommendations-for-new-binding)

---

## 1. Background: Two Reference Counting Systems

### 1.1 Python's Reference Counting

Python uses reference counting for memory management. The C API has strict semantics:

| Operation Type | Semantics | Example Functions |
|---------------|-----------|-------------------|
| **New Reference** | Caller owns the reference, must DECREF when done | `PyObject_Call`, `PyObject_Repr`, `PyObject_Str` |
| **Borrowed Reference** | Caller does NOT own, must INCREF to keep | `PyList_GetItem`, `PyTuple_GetItem`, `PyDict_GetItem` |
| **Stolen Reference** | Function takes ownership, caller must NOT DECREF | `PyList_SetItem`, `PyTuple_SetItem` |

### 1.2 MoonBit's Reference Counting

MoonBit uses automatic reference counting with a specific memory layout:

```c
struct moonbit_object {
  int32_t rc;      // reference count at offset -8
  uint32_t meta;   // metadata at offset -4
  // object data starts here (pointer points to this location)
};

#define Moonbit_object_header(obj) ((struct moonbit_object*)(obj) - 1)
```

**Critical:** MoonBit accesses the RC by going back 8 bytes from the object pointer.

---

## 2. Architecture Overview

### 2.1 Current Type Hierarchy

```
cpython/core.mbt:
  type PyObjectRef        // Abstract type representing PyObject*

obj.mbt:
  pub struct PyObject {
    priv obj : @cpython.PyObjectRef
  }

list.mbt, tuple.mbt, dict.mbt, etc:
  pub struct PyList {
    priv obj : PyObject
  }
```

### 2.2 Data Flow

```
[Python World]          [MoonBit World]
PyObject* ─────────────> PyObjectRef (abstract type)
                              │
                              └──> PyObject { obj: PyObjectRef }
                                       │
                                       └──> PyList { obj: PyObject }
```

### 2.3 Key Files

| File | Purpose |
|------|---------|
| `cpython/core.mbt` | Type definitions for PyObjectRef, py_incref, py_decref |
| `cpython/wrap.c` | C wrappers for Python C API calls |
| `obj.mbt` | PyObject struct definition |
| `list.mbt` | PyList implementation |
| `tuple.mbt` | PyTuple implementation |
| `dict.mbt` | PyDict implementation |
| `traits.mbt` | IsPyObject trait definition |

---

## 3. Category 1: Python C API Reference Counting Bugs

These bugs were present in the original code and have been fixed in commit `ffc7a7e`.

### 3.1 Borrowed Reference Bugs

**Problem:** Functions like `PyList_GetItem`, `PyTuple_GetItem`, `PyDict_GetItemString` return borrowed references. The original code wrapped these as owned without calling `Py_INCREF`.

**Locations:**

| File | Function | Line | Python C API |
|------|----------|------|--------------|
| `list.mbt` | `PyList::get` | 179 | `PyList_GetItem` |
| `tuple.mbt` | `PyTuple::get` | 124 | `PyTuple_GetItem` |
| `dict.mbt` | `PyDict::get` | 109 | `PyDict_GetItemString` |
| `dict.mbt` | `PyDict::getByObj` | 117 | `PyDict_GetItem` |

**Original Code (list.mbt:177-183):**

```moonbit
pub fn PyList::get(self : PyList, idx : Int) -> PyObjectEnum? {
  when(idx >= 0 && idx < self.len(), fn() {
    let item = @cpython.py_list_get_item(self.obj_ref(), idx.to_int64())
    // BUG: No py_incref - borrowed reference treated as owned
    item |> PyObject::create |> PyObjectEnum::create
  })
}
```

**Fix Applied:**

```moonbit
pub fn PyList::get(self : PyList, idx : Int) -> PyObjectEnum? {
  when(idx >= 0 && idx < self.len(), fn() {
    let item = @cpython.py_list_get_item(self.obj_ref(), idx.to_int64())
    @cpython.py_incref(item)  // PyList_GetItem returns borrowed reference
    item |> PyObject::create |> PyObjectEnum::create
  })
}
```

**Consequence:** Use-after-free when the container replaces the item.

### 3.2 Stolen Reference Bugs

**Problem:** Functions like `PyList_SetItem`, `PyTuple_SetItem` steal the reference. The original code didn't INCREF before passing, causing double-free when the MoonBit wrapper goes out of scope.

**Locations:**

| File | Function | Line | Python C API |
|------|----------|------|--------------|
| `list.mbt` | `PyList::set` | 231 | `PyList_SetItem` |
| `tuple.mbt` | `PyTuple::set` | 176 | `PyTuple_SetItem` |

**Original Code (list.mbt:225-238):**

```moonbit
pub fn[T : IsPyObject] PyList::set(
  self : PyList,
  idx : Int,
  item : T,
) -> Unit raise PyRuntimeError {
  guard idx >= 0 && idx < self.len() else { raise IndexOutOfBoundsError }
  // BUG: No py_incref before passing to stealing function
  let _ = @cpython.py_list_set_item(
    self.obj_ref(),
    idx.to_int64(),
    item.obj_ref(),
  )
}
```

**Fix Applied:**

```moonbit
pub fn[T : IsPyObject] PyList::set(
  self : PyList,
  idx : Int,
  item : T,
) -> Unit raise PyRuntimeError {
  guard idx >= 0 && idx < self.len() else { raise IndexOutOfBoundsError }
  @cpython.py_incref(item.obj_ref())  // PyList_SetItem steals reference
  let _ = @cpython.py_list_set_item(
    self.obj_ref(),
    idx.to_int64(),
    item.obj_ref(),
  )
}
```

**Consequence:** Double-free when the item is dropped by MoonBit.

### 3.3 Summary of Category 1 Fixes

All Python C API reference counting bugs have been fixed by:

- Adding `py_incref()` after borrowed reference returns
- Adding `py_incref()` before passing to stolen reference functions

---

## 4. Category 2: MoonBit RC System Incompatibility

### 4.1 The Problem (Now Fixed)

**MoonBit's compiler was treating `PyObjectRef` as a reference type and generating RC operations on it.**

When a `PyObjectRef` was stored in a MoonBit struct field, the compiler:

1. Detected it as a pointer field
2. Generated `moonbit_incref()` and `moonbit_decref()` calls
3. These calls accessed `ptr - 8` to find the RC header

**But Python objects don't have MoonBit headers!**

### 4.2 The Solution: `#external` Attribute

The fix is to mark `PyObjectRef` with the `#external` attribute:

```moonbit
// cpython/core.mbt:22 (FIXED)
#external
type PyObjectRef  // Abstract type - PyObject*
```

The `#external` attribute tells MoonBit that this type represents an external pointer that should NOT be RC-managed by MoonBit. The compiler no longer generates `moonbit_incref()`/`moonbit_decref()` calls for this type.

### 4.3 Original Problem Analysis

Without `#external`, the `type` keyword created an abstract type that MoonBit had no way to know was an external pointer.

```moonbit
// obj.mbt:16-18
pub struct PyObject {
  priv obj : @cpython.PyObjectRef
}
```

When `PyObjectRef` is stored in a struct field, MoonBit's compiler sees it as a reference field and generates RC operations.

### 4.3 Memory Layout Conflict

**MoonBit Object Layout:**

```
[rc: 4 bytes][meta: 4 bytes][object data...]
                            ^
                            └── pointer points here
```

**Python Object Layout:**

```
[Py_ssize_t ob_refcnt][PyTypeObject *ob_type][object data...]
^
└── PyObject* points here
```

When MoonBit does `Moonbit_object_header(ptr)` on a Python pointer, it reads garbage memory (or ASan red zones).

### 4.4 Why This Manifests with PYTHONMALLOC=malloc

Normally, Python uses pymalloc which pools memory. Objects are allocated from 256KB arenas with minimal overhead between allocations.

With `PYTHONMALLOC=malloc`:

- Each Python object is separately malloc'd
- ASan places red zones (poisoned memory) around each allocation
- When MoonBit reads `ptr - 8`, it hits ASan's red zone
- ASan reports: `heap-buffer-overflow` in `moonbit_incref_inlined`

**Without `PYTHONMALLOC=malloc`:** The reads at `ptr - 8` hit pymalloc's arena metadata, which happens to be valid memory. The bug is silent but still causes incorrect RC management.

---

## 5. Evidence: Generated C Code Analysis

### 5.1 PyFloat::to_string Generated Code

From `_build/native/release/test/test/test.blackbox_test.c:18309-18339`:

```c
moonbit_string_t $$...PyFloat$$to_string(
  struct $$...PyFloat* self$2117
) {
  struct $$...PyObject* _field$7554 = self$2117->$0;  // Get PyObject
  int32_t _cnt$8416 = Moonbit_object_header(self$2117)->rc;
  struct $$...PyObject* obj$6500;
  void* _field$7553;                                  // Will hold PyObjectRef
  int32_t _cnt$8418;
  void* obj$6499;

  if (_cnt$8416 > 1) {
    int32_t _new_cnt$8417 = _cnt$8416 - 1;
    Moonbit_object_header(self$2117)->rc = _new_cnt$8417;
    moonbit_incref(_field$7554);                      // This is fine
  } else if (_cnt$8416 == 1) {
    moonbit_free(self$2117);
  }

  obj$6500 = _field$7554;
  _field$7553 = obj$6500->$0;                         // Get raw PyObjectRef!
  _cnt$8418 = Moonbit_object_header(obj$6500)->rc;

  if (_cnt$8418 > 1) {
    int32_t _new_cnt$8419 = _cnt$8418 - 1;
    Moonbit_object_header(obj$6500)->rc = _new_cnt$8419;
    if (_field$7553) {
      moonbit_incref(_field$7553);                    // BUG! RC on Python ptr!
    }
  } else if (_cnt$8418 == 1) {
    moonbit_free(obj$6500);
  }

  obj$6499 = _field$7553;
  return $...py_object_moonbit_repr(obj$6499);
}
```

### 5.2 The Buggy Line

```c
moonbit_incref(_field$7553);
```

Where `_field$7553` is a `PyObjectRef` (raw `PyObject*`).

`moonbit_incref` does:

```c
void moonbit_incref(void *obj) {
  if (obj) {
    Moonbit_object_header(obj)->rc++;
  }
}
```

Which expands to:

```c
((struct moonbit_object*)(obj) - 1)->rc++;
```

This reads 8 bytes before the Python object - undefined behavior!

---

## 6. Impact and Manifestation

### 6.1 Symptoms

| Condition | Symptom |
|-----------|---------|
| Without ASan, pymalloc | Silent corruption, intermittent crashes |
| Without ASan, system malloc | Silent corruption, possible crashes |
| With ASan, pymalloc | May not detect (pooled memory) |
| With ASan, PYTHONMALLOC=malloc | `heap-buffer-overflow` at `moonbit_incref` |

### 6.2 Error Example

```
=================================================================
==12345==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x...
READ of size 4 at 0x... thread T0
    #0 0x... in moonbit_incref_inlined
    #1 0x... in $$...PyFloat$$to_string
    ...
0x... is located 8 bytes before 48-byte region [0x...,0x...)
allocated by thread T0 here:
    #0 0x... in malloc
    #1 0x... in _PyObject_Malloc
```

### 6.3 Current Status

- **Category 1 bugs:** Fixed in commit `ffc7a7e`
- **Category 2 bug:** Fixed by adding `#external` attribute to `PyObjectRef`

**All tests now pass with `PYTHONMALLOC=malloc` + ASan**, confirming proper memory management.

---

## 7. Solution Applied

### 7.1 The `#external` Attribute (Implemented)

MoonBit provides the `#external` attribute for exactly this use case:

```moonbit
#external
type PyObjectRef  // Compiler knows not to apply RC
```

**Result:**
- MoonBit no longer generates `moonbit_incref()`/`moonbit_decref()` on `PyObjectRef`
- Python pointers are left alone by MoonBit's RC system
- All tests pass with `PYTHONMALLOC=malloc` + ASan

### 7.2 Generated Code Comparison

**Before (without `#external`):**
```c
_field$7553 = obj$6500->$0;
_cnt$8418 = Moonbit_object_header(obj$6500)->rc;
if (_cnt$8418 > 1) {
    ...
    if (_field$7553) {
      moonbit_incref(_field$7553);  // BUG! RC on Python pointer
    }
} ...
```

**After (with `#external`):**
```c
_field$7553 = obj$6500->$0;
moonbit_decref(obj$6500);         // Only RC the wrapper, not the Python ptr
obj$6499 = _field$7553;
```

### 7.3 Architectural Guidelines

1. **Mark external pointers with `#external`**
   - Use `#external` on any type representing foreign pointers
   - This prevents MoonBit from applying RC to them

2. **Explicit Python RC management**
   - Use `py_incref()` for borrowed references
   - Use `py_incref()` before stolen reference calls
   - Wrapper `drop()` methods call `py_decref()`

3. **Separate RC systems completely**
   - MoonBit RC manages MoonBit wrapper structs
   - Python RC managed via explicit `py_incref()`/`py_decref()` calls

4. **Comprehensive testing with ASan**
   - Always test with `PYTHONMALLOC=malloc` during development
   - Use ASan to catch memory issues early

---

## 8. Automatic Memory Management: Attempted and Reverted

### 8.1 The Attempt

An attempt was made to implement automatic memory management using `moonbit_make_external_object` with a finalizer that calls `Py_DECREF`. The approach:

```
PyObjectRef (#external, no auto cleanup)
     ↓
PyObjectHandle (external object WITH finalizer → calls py_decref)
     ↓
PyObject { handle: PyObjectHandle }  (MoonBit struct)
```

When `PyObject` is freed by MoonBit RC → `PyObjectHandle` RC drops → finalizer calls `py_decref()`.

### 8.2 Why It Failed

MoonBit's RC behavior is **too eager**. When accessing struct fields, the compiler generates code that decrefs the parent struct **before** the returned value is fully used:

```c
// Generated code for obj_ref():
_field = obj->handle;        // Extract handle
moonbit_decref(obj);         // Decref obj -> may free obj -> frees handle
_tmp = py_object_handle_get(_field);  // Use handle (may be freed!)
moonbit_decref(_field);      // Triggers finalizer -> Py_DECREF
return _tmp;                 // Return PyObjectRef (Python object may be freed!)
```

The handle's finalizer runs **before** we're done using the returned `PyObjectRef`, causing use-after-free crashes.

### 8.3 Attempted Fixes That Didn't Work

1. **Caching py_ref separately**: Stored both `handle` and `py_ref` in `PyObject`. Didn't help - handle still gets freed when PyObject is freed, triggering the finalizer.

2. **Using `#borrow` attribute**: Added `#borrow(handle)` to `py_object_handle_get`. This only affects what happens inside the function, not what the caller does after.

3. **Storing both handle and ref**: Same issue - when PyObject is freed (because it's the last reference), the handle is freed and finalizer runs.

### 8.4 Conclusion

Automatic memory management is **not achievable** with the current MoonBit RC behavior. Manual `drop()` calls remain the only safe approach.

Future possibilities:
- MoonBit language change: A way to keep struct alive while using returned field values
- API redesign: Return a tuple `(PyObjectRef, Guard)` where Guard keeps the handle alive
- MoonBit Drop trait: If MoonBit adds automatic `drop()` calls on scope exit

---

## Appendix A: Key Source Code References

### A.1 MoonBit Runtime (moonbit.h)

```c
struct moonbit_object {
  int32_t rc;
  uint32_t meta;
};

#define Moonbit_object_header(obj) ((struct moonbit_object*)(obj) - 1)

MOONBIT_EXPORT void moonbit_incref(void *obj);
MOONBIT_EXPORT void moonbit_decref(void *obj);
```

### A.2 PyObjectRef Definition (cpython/core.mbt)

```moonbit
#external
type PyObjectRef  // PyObject* - #external prevents MoonBit RC interference

#owned(obj)
pub extern "C" fn py_incref(obj : PyObjectRef) = "py_incref"

#owned(obj)
pub extern "C" fn py_decref(obj : PyObjectRef) = "py_decref"
```

### A.3 PyObject Struct (obj.mbt)

```moonbit
pub struct PyObject {
  priv obj : @cpython.PyObjectRef  // Safe with #external on PyObjectRef
}
```

---

## Appendix B: Test Cases for RC Bugs

Located in `test/object_test.mbt`:

| Test Name | Bug Type | Fixed |
|-----------|----------|-------|
| RC Bug - PyList set steals reference | Stolen ref | Yes |
| RC Bug - PyList get borrowed reference | Borrowed ref | Yes |
| RC Bug - PyTuple set steals reference | Stolen ref | Yes |
| RC Bug - PyTuple get borrowed reference | Borrowed ref | Yes |
| RC Bug - PyDict get borrowed reference | Borrowed ref | Yes |

---

## Appendix C: Commit History

| Commit | Description |
|--------|-------------|
| `6b98195` | fix(rc): add #external to PyObjectRef to prevent MoonBit RC interference |
| `ffc7a7e` | fix(rc): correct reference counting for borrowed/stolen references |
| `2f2eca0` | docs(skill): clarify -F glob patterns and PYTHONMALLOC warning |
| `5e9124b` | chore: add moon-test skill for Claude Code |
| `6f30521` | demo: add RC bug demonstration with address sanitizer |

---

*End of Report*
