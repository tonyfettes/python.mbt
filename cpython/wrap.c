#include "moonbit.h"
#include <Python.h>
#include <stdlib.h>
#include <string.h>

void *moonbit_str_to_c_str(moonbit_string_t ms) {
  int32_t len = Moonbit_array_length(ms);
  char *ptr = (char *)malloc(len + 1);
  for (int i = 0; i < len; i++) {
    if (ms[i] < 0x80) {
      ptr[i] = ms[i];
    } else {
      ptr[i] = '?';
    }
  }
  ptr[len] = '\0';
  return ptr;
}

moonbit_string_t c_str_to_moonbit_str(void *ptr) {
  char *cptr = (char *)ptr;
  int32_t len = strlen(cptr);
  moonbit_string_t ms = moonbit_make_string(len, 0);
  for (int i = 0; i < len; i++) {
    ms[i] = (uint16_t)cptr[i];
  }
  // free(ptr);
  return ms;
}

moonbit_string_t c_str_to_moonbit_str_with_length(void *ptr, unsigned len) {
  char *cptr = (char *)ptr;
  moonbit_string_t ms = moonbit_make_string(len, 0);
  for (int i = 0; i < len; i++) {
    ms[i] = (uint16_t)cptr[i];
  }
  // free(ptr);
  return ms;
}

void print_pyobject(PyObject *obj) { PyObject_Print(obj, stdout, 0); }

void py_incref(PyObject *obj) { Py_INCREF(obj); }

void py_decref(PyObject *obj) { Py_DECREF(obj); }

int64_t py_refcnt(PyObject *obj) { return Py_REFCNT(obj); }

int Moonbit_PyObjectRef_is_null(PyObject *obj) { return obj == NULL; }

PyTypeObject *py_type(PyObject *obj) { return obj->ob_type; }

int py_tuple_check(PyObject *obj) { return PyTuple_Check(obj); }

int py_list_check(PyObject *obj) { return PyList_Check(obj); }

int py_dict_check(PyObject *obj) { return PyDict_Check(obj); }

int py_set_check(PyObject *obj) { return PySet_Check(obj); }

int py_string_check(PyObject *obj) { return PyUnicode_Check(obj); }

int py_int_check(PyObject *obj) { return PyLong_Check(obj); }

int py_float_check(PyObject *obj) { return PyFloat_Check(obj); }

int py_bool_check(PyObject *obj) { return PyBool_Check(obj); }

int py_none_check(PyObject *obj) { return Py_None == obj; }

int py_callable_check(PyObject *obj) { return PyCallable_Check(obj); }

int py_iter_check(PyObject *obj) { return PyIter_Check(obj); }

int py_module_check(PyObject *obj) { return PyModule_Check(obj); }

int py_type_check(PyObject *obj) { return PyType_Check(obj); }

int py_function_check(PyObject *obj) { return PyFunction_Check(obj); }

int py_method_check(PyObject *obj) { return PyMethod_Check(obj); }

int py_is_true(PyObject *obj) { return 0 != Py_IsTrue(obj); };

int py_is_false(PyObject *obj) { return 0 == Py_IsTrue(obj); }

PyObject *py_import_import_module(const char *name) {
  PyObject *module = PyImport_ImportModule(name);
  return module;
}

moonbit_string_t py_unicode_as_moonbit_string(PyObject *obj) {
  void *data = PyUnicode_DATA(obj);
  int64_t len = PyUnicode_GET_LENGTH(obj);
  moonbit_string_t ms = moonbit_make_string(len, 0);
  if (PyUnicode_KIND(obj) == PyUnicode_2BYTE_KIND) {
    memcpy(ms, data, len * 2);
  } else if (PyUnicode_KIND(obj) == PyUnicode_1BYTE_KIND) {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS1 *)data)[i]);
    }
  } else { // PyUnicode_4BYTE_KIND
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS4 *)data)[i]);
    }
  }
  return ms;
}

// PyObjectHandle - MoonBit-managed wrapper with automatic py_decref on cleanup

// Finalizer called when MoonBit RC drops to 0
static void py_object_handle_release(void *self) {
  PyObject **ptr = (PyObject **)self;
  if (*ptr != NULL) {
    Py_DECREF(*ptr);
  }
}

// Create handle (wraps PyObject* with auto-cleanup)
void *py_object_handle_new(PyObject *obj) {
  void *handle =
      moonbit_make_external_object(py_object_handle_release, sizeof(PyObject *));
  *(PyObject **)handle = obj;
  return handle;
}

// Get raw PyObject* from handle
PyObject *py_object_handle_get(void *handle) {
  return *(PyObject **)handle;
}

// ============================================================================
// Handle-aware wrappers - these take PyObjectHandle and extract PyObject*
// internally, keeping the handle alive during the operation
// ============================================================================

// Helper macro to extract PyObject* from handle
#define HANDLE_GET(h) (*(PyObject **)(h))

// Type check functions (handle-aware)
int py_bool_check_h(void *handle) { return PyBool_Check(HANDLE_GET(handle)); }

int py_int_check_h(void *handle) { return PyLong_Check(HANDLE_GET(handle)); }

int py_float_check_h(void *handle) { return PyFloat_Check(HANDLE_GET(handle)); }

int py_string_check_h(void *handle) {
  return PyUnicode_Check(HANDLE_GET(handle));
}

int py_list_check_h(void *handle) { return PyList_Check(HANDLE_GET(handle)); }

int py_tuple_check_h(void *handle) { return PyTuple_Check(HANDLE_GET(handle)); }

int py_dict_check_h(void *handle) { return PyDict_Check(HANDLE_GET(handle)); }

int py_set_check_h(void *handle) { return PySet_Check(HANDLE_GET(handle)); }

int py_module_check_h(void *handle) {
  return PyModule_Check(HANDLE_GET(handle));
}

int py_callable_check_h(void *handle) {
  return PyCallable_Check(HANDLE_GET(handle));
}

int py_none_check_h(void *handle) { return Py_None == HANDLE_GET(handle); }

int py_function_check_h(void *handle) {
  return PyFunction_Check(HANDLE_GET(handle));
}

int py_iter_check_h(void *handle) { return PyIter_Check(HANDLE_GET(handle)); }

int py_handle_is_null(void *handle) { return HANDLE_GET(handle) == NULL; }

// Numeric operations (handle-aware)
double py_float_as_double_h(void *handle) {
  return PyFloat_AsDouble(HANDLE_GET(handle));
}

int64_t py_long_as_long_h(void *handle) {
  return PyLong_AsLong(HANDLE_GET(handle));
}

double py_long_as_double_h(void *handle) {
  return PyLong_AsDouble(HANDLE_GET(handle));
}

// Object operations (handle-aware)
int py_object_is_true_h(void *handle) {
  return PyObject_IsTrue(HANDLE_GET(handle));
}

void print_pyobject_h(void *handle) {
  PyObject_Print(HANDLE_GET(handle), stdout, 0);
}

PyTypeObject *py_type_h(void *handle) { return HANDLE_GET(handle)->ob_type; }

PyObject *py_object_get_attr_string_h(void *handle, const char *attr) {
  return PyObject_GetAttrString(HANDLE_GET(handle), attr);
}

// String operations (handle-aware) - returns new MoonBit string
moonbit_string_t py_unicode_as_moonbit_string_h(void *handle) {
  PyObject *obj = HANDLE_GET(handle);
  void *data = PyUnicode_DATA(obj);
  int64_t len = PyUnicode_GET_LENGTH(obj);
  moonbit_string_t ms = moonbit_make_string(len, 0);
  if (PyUnicode_KIND(obj) == PyUnicode_2BYTE_KIND) {
    memcpy(ms, data, len * 2);
  } else if (PyUnicode_KIND(obj) == PyUnicode_1BYTE_KIND) {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS1 *)data)[i]);
    }
  } else { // PyUnicode_4BYTE_KIND
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS4 *)data)[i]);
    }
  }
  return ms;
}

// PyObject repr/str to MoonBit string (handle-aware)
moonbit_string_t py_object_repr_h(void *handle) {
  PyObject *repr = PyObject_Repr(HANDLE_GET(handle));
  if (repr == NULL) {
    return moonbit_make_string(0, 0);
  }
  void *data = PyUnicode_DATA(repr);
  int64_t len = PyUnicode_GET_LENGTH(repr);
  moonbit_string_t ms = moonbit_make_string(len, 0);
  if (PyUnicode_KIND(repr) == PyUnicode_2BYTE_KIND) {
    memcpy(ms, data, len * 2);
  } else if (PyUnicode_KIND(repr) == PyUnicode_1BYTE_KIND) {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS1 *)data)[i]);
    }
  } else {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS4 *)data)[i]);
    }
  }
  Py_DECREF(repr);
  return ms;
}

moonbit_string_t py_object_str_h(void *handle) {
  PyObject *str = PyObject_Str(HANDLE_GET(handle));
  if (str == NULL) {
    return moonbit_make_string(0, 0);
  }
  void *data = PyUnicode_DATA(str);
  int64_t len = PyUnicode_GET_LENGTH(str);
  moonbit_string_t ms = moonbit_make_string(len, 0);
  if (PyUnicode_KIND(str) == PyUnicode_2BYTE_KIND) {
    memcpy(ms, data, len * 2);
  } else if (PyUnicode_KIND(str) == PyUnicode_1BYTE_KIND) {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS1 *)data)[i]);
    }
  } else {
    for (int i = 0; i < len; i++) {
      ms[i] = (uint16_t)(((Py_UCS4 *)data)[i]);
    }
  }
  Py_DECREF(str);
  return ms;
}

// ============================================================================
// List operations (handle-aware)
// ============================================================================

int64_t py_list_size_h(void *handle) {
  return PyList_Size(HANDLE_GET(handle));
}

int py_list_append_h(void *list_handle, void *item_handle) {
  return PyList_Append(HANDLE_GET(list_handle), HANDLE_GET(item_handle));
}

// Returns a new handle (caller owns the reference)
void *py_list_get_item_h(void *list_handle, int64_t idx) {
  PyObject *item = PyList_GetItem(HANDLE_GET(list_handle), idx);
  if (item == NULL) {
    return py_object_handle_new(NULL);
  }
  Py_INCREF(item); // PyList_GetItem returns borrowed reference
  return py_object_handle_new(item);
}

int py_list_set_item_h(void *list_handle, int64_t idx, void *item_handle) {
  PyObject *item = HANDLE_GET(item_handle);
  Py_INCREF(item); // PyList_SetItem steals reference
  return PyList_SetItem(HANDLE_GET(list_handle), idx, item);
}

// ============================================================================
// Tuple operations (handle-aware)
// ============================================================================

uint64_t py_tuple_size_h(void *handle) {
  return PyTuple_Size(HANDLE_GET(handle));
}

// Returns a new handle (caller owns the reference)
void *py_tuple_get_item_h(void *tuple_handle, uint64_t idx) {
  PyObject *item = PyTuple_GetItem(HANDLE_GET(tuple_handle), idx);
  if (item == NULL) {
    return py_object_handle_new(NULL);
  }
  Py_INCREF(item); // PyTuple_GetItem returns borrowed reference
  return py_object_handle_new(item);
}

int py_tuple_set_item_h(void *tuple_handle, uint64_t idx, void *item_handle) {
  PyObject *item = HANDLE_GET(item_handle);
  Py_INCREF(item); // PyTuple_SetItem steals reference
  return PyTuple_SetItem(HANDLE_GET(tuple_handle), idx, item);
}

// ============================================================================
// Dict operations (handle-aware)
// ============================================================================

uint64_t py_dict_size_h(void *handle) {
  return PyDict_Size(HANDLE_GET(handle));
}

// Returns a new handle (caller owns the reference)
void *py_dict_get_item_string_h(void *dict_handle, const char *key) {
  PyObject *item = PyDict_GetItemString(HANDLE_GET(dict_handle), key);
  if (item == NULL) {
    return py_object_handle_new(NULL);
  }
  Py_INCREF(item); // PyDict_GetItemString returns borrowed reference
  return py_object_handle_new(item);
}

int py_dict_set_item_string_h(void *dict_handle, const char *key,
                              void *item_handle) {
  return PyDict_SetItemString(HANDLE_GET(dict_handle), key,
                              HANDLE_GET(item_handle));
}

// Returns a new handle (caller owns the reference)
void *py_dict_get_item_h(void *dict_handle, void *key_handle) {
  PyObject *item =
      PyDict_GetItem(HANDLE_GET(dict_handle), HANDLE_GET(key_handle));
  if (item == NULL) {
    return py_object_handle_new(NULL);
  }
  Py_INCREF(item); // PyDict_GetItem returns borrowed reference
  return py_object_handle_new(item);
}

int py_dict_set_item_h(void *dict_handle, void *key_handle,
                       void *item_handle) {
  return PyDict_SetItem(HANDLE_GET(dict_handle), HANDLE_GET(key_handle),
                        HANDLE_GET(item_handle));
}

int py_dict_contains_h(void *dict_handle, void *key_handle) {
  return PyDict_Contains(HANDLE_GET(dict_handle), HANDLE_GET(key_handle));
}

// Returns a new handle (caller owns the reference)
void *py_dict_keys_h(void *dict_handle) {
  PyObject *keys = PyDict_Keys(HANDLE_GET(dict_handle));
  return py_object_handle_new(keys);
}

// Returns a new handle (caller owns the reference)
void *py_dict_values_h(void *dict_handle) {
  PyObject *values = PyDict_Values(HANDLE_GET(dict_handle));
  return py_object_handle_new(values);
}

// Returns a new handle (caller owns the reference)
void *py_dict_items_h(void *dict_handle) {
  PyObject *items = PyDict_Items(HANDLE_GET(dict_handle));
  return py_object_handle_new(items);
}

// ============================================================================
// Call operations (handle-aware)
// ============================================================================

// Returns a new handle (caller owns the reference)
void *py_object_call_h(void *callable_handle, void *args_handle,
                       void *kwargs_handle) {
  PyObject *result =
      PyObject_Call(HANDLE_GET(callable_handle), HANDLE_GET(args_handle),
                    HANDLE_GET(kwargs_handle));
  return py_object_handle_new(result);
}

// Returns a new handle (caller owns the reference)
void *py_object_call_object_h(void *callable_handle, void *args_handle) {
  PyObject *result =
      PyObject_CallObject(HANDLE_GET(callable_handle), HANDLE_GET(args_handle));
  return py_object_handle_new(result);
}
