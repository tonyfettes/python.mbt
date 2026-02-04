// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
type CStr // const char*

///|
type CWStr // const wchar_t*

///|
#external
type PyObjectRef // PyObject*

///|
type PyThreadStateRef // PyThreadState*

///|
type PyCodeObjectRef // PyCodeObject*

///|
type ArrayPyObjectRef // PyObject*[]

///|
type PyTypeObjectRef

///|
#borrow(s)
extern "C" fn moonbit_str_to_c_str(s : String) -> CStr = "moonbit_str_to_c_str"

///|
#owned(s)
extern "C" fn c_str_to_moonbit_str(s : CStr) -> String = "c_str_to_moonbit_str"

///|
#owned(s)
extern "C" fn c_str_to_moonbit_str_with_length(s : CStr, len : UInt) -> String = "c_str_to_moonbit_str_with_length"

///|
//extern "C" fn moonbit_str_to_cw_str(s : String) -> CWStr = "moonbit_str_to_cw_str"

///|
//extern "C" fn cw_str_to_moonbit_str(s : CWStr) -> String = "cw_str_to_moonbit_str"

///|
//extern "C" fn cw_str_to_moonbit_str_with_length(
//  s : CWStr,
//  len : UInt
//) -> String = "cw_str_to_moonbit_str_with_length"

///|
fn CStr::from(s : String) -> CStr {
  moonbit_str_to_c_str(s)
}

///|
fn CStr::to_string(self : CStr) -> String {
  c_str_to_moonbit_str(self)
}

///|
fn CStr::to_string_with_length(self : CStr, len : UInt) -> String {
  c_str_to_moonbit_str_with_length(self, len)
}

///|
test {
  ignore(CStr::to_string_with_length)
  //ignore(CWStr::from)
}

///|
//fn CWStr::from(s : String) -> CWStr {
//  moonbit_str_to_cw_str(s)
//}

///|
//fn CWStr::to_string(self : CWStr) -> String {
//  cw_str_to_moonbit_str(self)
//}
//
/////|
//fn CWStr::to_string_with_length(self : CWStr, len : UInt) -> String {
//  cw_str_to_moonbit_str_with_length(self, len)
//}

///|
//test {
//  ignore(CWStr::to_string_with_length)
//  ignore(CWStr::to_string)
//}

///|
#owned(obj)
extern "C" fn py_object_is_null(obj : PyObjectRef) -> Int = "Moonbit_PyObjectRef_is_null"

///|
pub fn PyObjectRef::is_null(self : PyObjectRef) -> Bool {
  py_object_is_null(self) != 0
}

///|
#owned(obj)
pub extern "C" fn print_pyobject(obj : PyObjectRef) = "print_pyobject"

///|
pub fn PyObjectRef::dump(self : PyObjectRef) -> Unit {
  print_pyobject(self)
}

///|
#owned(obj)
pub extern "C" fn py_incref(obj : PyObjectRef) = "py_incref"

///|
#owned(obj)
pub extern "C" fn py_decref(obj : PyObjectRef) = "py_decref"

///|
#owned(obj)
pub extern "C" fn py_refcnt(obj : PyObjectRef) -> Int64 = "py_refcnt"

///| Handle with automatic cleanup (NOT #external - MoonBit RC manages it)
type PyObjectHandle

///| Create handle from PyObjectRef (takes ownership of the reference)
pub extern "C" fn py_object_handle_new(obj : PyObjectRef) -> PyObjectHandle = "py_object_handle_new"

///| Get raw PyObjectRef from handle (borrowed - do not decref)
#borrow(handle)
pub extern "C" fn py_object_handle_get(handle : PyObjectHandle) -> PyObjectRef = "py_object_handle_get"

// ============================================================================
// Handle-aware functions - these take PyObjectHandle directly, keeping
// the handle alive during the operation (solves the early-decref problem)
// ============================================================================

// Type check functions (handle-aware)
///|
#borrow(handle)
extern "C" fn __py_bool_check_h(handle : PyObjectHandle) -> Int = "py_bool_check_h"

///|
pub fn py_bool_check_h(handle : PyObjectHandle) -> Bool {
  __py_bool_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_int_check_h(handle : PyObjectHandle) -> Int = "py_int_check_h"

///|
pub fn py_int_check_h(handle : PyObjectHandle) -> Bool {
  __py_int_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_float_check_h(handle : PyObjectHandle) -> Int = "py_float_check_h"

///|
pub fn py_float_check_h(handle : PyObjectHandle) -> Bool {
  __py_float_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_string_check_h(handle : PyObjectHandle) -> Int = "py_string_check_h"

///|
pub fn py_string_check_h(handle : PyObjectHandle) -> Bool {
  __py_string_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_list_check_h(handle : PyObjectHandle) -> Int = "py_list_check_h"

///|
pub fn py_list_check_h(handle : PyObjectHandle) -> Bool {
  __py_list_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_tuple_check_h(handle : PyObjectHandle) -> Int = "py_tuple_check_h"

///|
pub fn py_tuple_check_h(handle : PyObjectHandle) -> Bool {
  __py_tuple_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_dict_check_h(handle : PyObjectHandle) -> Int = "py_dict_check_h"

///|
pub fn py_dict_check_h(handle : PyObjectHandle) -> Bool {
  __py_dict_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_set_check_h(handle : PyObjectHandle) -> Int = "py_set_check_h"

///|
pub fn py_set_check_h(handle : PyObjectHandle) -> Bool {
  __py_set_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_module_check_h(handle : PyObjectHandle) -> Int = "py_module_check_h"

///|
pub fn py_module_check_h(handle : PyObjectHandle) -> Bool {
  __py_module_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_callable_check_h(handle : PyObjectHandle) -> Int = "py_callable_check_h"

///|
pub fn py_callable_check_h(handle : PyObjectHandle) -> Bool {
  __py_callable_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_none_check_h(handle : PyObjectHandle) -> Int = "py_none_check_h"

///|
pub fn py_none_check_h(handle : PyObjectHandle) -> Bool {
  __py_none_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_function_check_h(handle : PyObjectHandle) -> Int = "py_function_check_h"

///|
pub fn py_function_check_h(handle : PyObjectHandle) -> Bool {
  __py_function_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_iter_check_h(handle : PyObjectHandle) -> Int = "py_iter_check_h"

///|
pub fn py_iter_check_h(handle : PyObjectHandle) -> Bool {
  __py_iter_check_h(handle) != 0
}

///|
#borrow(handle)
extern "C" fn __py_handle_is_null(handle : PyObjectHandle) -> Int = "py_handle_is_null"

///|
pub fn py_handle_is_null(handle : PyObjectHandle) -> Bool {
  __py_handle_is_null(handle) != 0
}

// Numeric operations (handle-aware)
///|
#borrow(handle)
pub extern "C" fn py_float_as_double_h(handle : PyObjectHandle) -> Double = "py_float_as_double_h"

///|
#borrow(handle)
pub extern "C" fn py_long_as_long_h(handle : PyObjectHandle) -> Int64 = "py_long_as_long_h"

///|
#borrow(handle)
pub extern "C" fn py_long_as_double_h(handle : PyObjectHandle) -> Double = "py_long_as_double_h"

// Object operations (handle-aware)
///|
#borrow(handle)
extern "C" fn __py_object_is_true_h(handle : PyObjectHandle) -> Int = "py_object_is_true_h"

///|
pub fn py_object_is_true_h(handle : PyObjectHandle) -> Bool {
  __py_object_is_true_h(handle) != 0
}

///|
#borrow(handle)
pub extern "C" fn print_pyobject_h(handle : PyObjectHandle) = "print_pyobject_h"

///|
#borrow(handle)
pub extern "C" fn py_type_h(handle : PyObjectHandle) -> PyTypeObjectRef = "py_type_h"

///|
#borrow(handle, attr)
extern "C" fn __py_object_get_attr_string_h(
  handle : PyObjectHandle,
  attr : Bytes,
) -> PyObjectRef = "py_object_get_attr_string_h"

///|
pub fn py_object_get_attr_string_h(
  handle : PyObjectHandle,
  attr : String,
) -> PyObjectRef {
  let attr = ToCStr::to_cstr(attr)
  __py_object_get_attr_string_h(handle, attr)
}

// String operations (handle-aware)
///|
#borrow(handle)
pub extern "C" fn py_unicode_as_moonbit_string_h(handle : PyObjectHandle) -> String = "py_unicode_as_moonbit_string_h"

///|
#borrow(handle)
pub extern "C" fn py_object_repr_h(handle : PyObjectHandle) -> String = "py_object_repr_h"

///|
#borrow(handle)
pub extern "C" fn py_object_str_h(handle : PyObjectHandle) -> String = "py_object_str_h"

// ============================================================================
// List operations (handle-aware)
// ============================================================================

///|
#borrow(handle)
pub extern "C" fn py_list_size_h(handle : PyObjectHandle) -> Int64 = "py_list_size_h"

///|
#borrow(list, item)
pub extern "C" fn py_list_append_h(
  list : PyObjectHandle,
  item : PyObjectHandle,
) -> Int = "py_list_append_h"

///| Returns a new handle (caller owns the reference)
#borrow(list)
pub extern "C" fn py_list_get_item_h(
  list : PyObjectHandle,
  idx : Int64,
) -> PyObjectHandle = "py_list_get_item_h"

///|
#borrow(list, item)
pub extern "C" fn py_list_set_item_h(
  list : PyObjectHandle,
  idx : Int64,
  item : PyObjectHandle,
) -> Int = "py_list_set_item_h"

// ============================================================================
// Tuple operations (handle-aware)
// ============================================================================

///|
#borrow(handle)
pub extern "C" fn py_tuple_size_h(handle : PyObjectHandle) -> UInt64 = "py_tuple_size_h"

///| Returns a new handle (caller owns the reference)
#borrow(tuple)
pub extern "C" fn py_tuple_get_item_h(
  tuple : PyObjectHandle,
  idx : UInt64,
) -> PyObjectHandle = "py_tuple_get_item_h"

///|
#borrow(tuple, item)
pub extern "C" fn py_tuple_set_item_h(
  tuple : PyObjectHandle,
  idx : UInt64,
  item : PyObjectHandle,
) -> Int = "py_tuple_set_item_h"

// ============================================================================
// Dict operations (handle-aware)
// ============================================================================

///|
#borrow(handle)
pub extern "C" fn py_dict_size_h(handle : PyObjectHandle) -> UInt64 = "py_dict_size_h"

///| Returns a new handle (caller owns the reference)
#borrow(dict, key)
extern "C" fn __py_dict_get_item_string_h(
  dict : PyObjectHandle,
  key : Bytes,
) -> PyObjectHandle = "py_dict_get_item_string_h"

///|
pub fn py_dict_get_item_string_h(
  dict : PyObjectHandle,
  key : String,
) -> PyObjectHandle {
  let key = ToCStr::to_cstr(key)
  __py_dict_get_item_string_h(dict, key)
}

///|
#borrow(dict, key, item)
extern "C" fn __py_dict_set_item_string_h(
  dict : PyObjectHandle,
  key : Bytes,
  item : PyObjectHandle,
) -> Int = "py_dict_set_item_string_h"

///|
pub fn py_dict_set_item_string_h(
  dict : PyObjectHandle,
  key : String,
  item : PyObjectHandle,
) -> Int {
  let key = ToCStr::to_cstr(key)
  __py_dict_set_item_string_h(dict, key, item)
}

///| Returns a new handle (caller owns the reference)
#borrow(dict, key)
pub extern "C" fn py_dict_get_item_h(
  dict : PyObjectHandle,
  key : PyObjectHandle,
) -> PyObjectHandle = "py_dict_get_item_h"

///|
#borrow(dict, key, item)
pub extern "C" fn py_dict_set_item_h(
  dict : PyObjectHandle,
  key : PyObjectHandle,
  item : PyObjectHandle,
) -> Int = "py_dict_set_item_h"

///|
#borrow(dict, key)
pub extern "C" fn py_dict_contains_h(
  dict : PyObjectHandle,
  key : PyObjectHandle,
) -> Int = "py_dict_contains_h"

///| Returns a new handle (caller owns the reference)
#borrow(dict)
pub extern "C" fn py_dict_keys_h(dict : PyObjectHandle) -> PyObjectHandle = "py_dict_keys_h"

///| Returns a new handle (caller owns the reference)
#borrow(dict)
pub extern "C" fn py_dict_values_h(dict : PyObjectHandle) -> PyObjectHandle = "py_dict_values_h"

///| Returns a new handle (caller owns the reference)
#borrow(dict)
pub extern "C" fn py_dict_items_h(dict : PyObjectHandle) -> PyObjectHandle = "py_dict_items_h"

// ============================================================================
// Call operations (handle-aware)
// ============================================================================

///| Returns a new handle (caller owns the reference)
#borrow(callable, args, kwargs)
pub extern "C" fn py_object_call_h(
  callable : PyObjectHandle,
  args : PyObjectHandle,
  kwargs : PyObjectHandle,
) -> PyObjectHandle = "py_object_call_h"

///| Returns a new handle (caller owns the reference)
#borrow(callable, args)
pub extern "C" fn py_object_call_object_h(
  callable : PyObjectHandle,
  args : PyObjectHandle,
) -> PyObjectHandle = "py_object_call_object_h"

