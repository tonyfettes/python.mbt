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
/// PyObject is now a newtype wrapper around PyObjectHandle.
/// This eliminates the struct field access problem where extracting a field
/// would trigger early cleanup of the handle.
pub struct PyObject(@cpython.PyObjectHandle)

///|
/// Get the underlying handle directly.
pub fn PyObject::handle(self : PyObject) -> @cpython.PyObjectHandle {
  self.0
}

///|
/// Get the raw PyObjectRef - WARNING: This can cause use-after-free if handle
/// is not kept alive. Prefer using handle with handle-aware functions.
fn PyObject::obj_ref(self : PyObject) -> @cpython.PyObjectRef {
  @cpython.py_object_handle_get(self.0)
}

///|
pub fn PyObject::create(obj : @cpython.PyObjectRef) -> PyObject {
  PyObject(@cpython.py_object_handle_new(obj))
}

///|
pub fn PyObject::is_null(self : PyObject) -> Bool {
  @cpython.py_handle_is_null(self.0)
}

///|
pub fn PyObject::is_bool(self : PyObject) -> Bool {
  @cpython.py_bool_check_h(self.0)
}

///|
pub fn PyObject::is_int(self : PyObject) -> Bool {
  @cpython.py_int_check_h(self.0)
}

///|
pub fn PyObject::is_float(self : PyObject) -> Bool {
  @cpython.py_float_check_h(self.0)
}

///|
pub fn PyObject::is_string(self : PyObject) -> Bool {
  @cpython.py_string_check_h(self.0)
}

///|
pub fn PyObject::is_list(self : PyObject) -> Bool {
  @cpython.py_list_check_h(self.0)
}

///|
pub fn PyObject::is_tuple(self : PyObject) -> Bool {
  @cpython.py_tuple_check_h(self.0)
}

///|
pub fn PyObject::is_dict(self : PyObject) -> Bool {
  @cpython.py_dict_check_h(self.0)
}

///|
pub fn PyObject::is_module(self : PyObject) -> Bool {
  @cpython.py_module_check_h(self.0)
}

///|
pub fn PyObject::is_callable(self : PyObject) -> Bool {
  @cpython.py_callable_check_h(self.0)
}

///|
pub fn PyObject::type_of(self : PyObject) -> PyType {
  if @cpython.py_bool_check_h(self.0) {
    PyType::PyBool
  } else if @cpython.py_int_check_h(self.0) {
    PyType::PyInteger
  } else if @cpython.py_float_check_h(self.0) {
    PyType::PyFloat
  } else if @cpython.py_string_check_h(self.0) {
    PyType::PyString
  } else if @cpython.py_list_check_h(self.0) {
    PyType::PyList
  } else if @cpython.py_tuple_check_h(self.0) {
    PyType::PyTuple
  } else if @cpython.py_dict_check_h(self.0) {
    PyType::PyDict
  } else if @cpython.py_module_check_h(self.0) {
    PyType::PyModule
  } else if @cpython.py_callable_check_h(self.0) {
    PyType::PyCallable
  } else {
    PyType::PyClass
  }
}

///|
pub fn PyObject::dump(self : PyObject) -> Unit {
  @cpython.print_pyobject_h(self.0)
}

///|
/// No longer needed - memory is automatically managed via handle finalizer.
pub fn PyObject::drop(self : PyObject) -> Unit {
  ignore(self)
}

///|
pub fn PyObject::type_name(self : PyObject) -> String {
  let ty = @cpython.py_type_h(self.0)
  let tyname = @cpython.py_type_name(ty)
  tyname
}

///|
pub fn PyObject::try_get_attr(
  self : PyObject,
  attr : String,
  print_err? : Bool = false,
) -> PyObjectEnum? {
  let f = @cpython.py_object_get_attr_string_h(self.0, attr)
  if f.is_null() {
    if print_err {
      @cpython.py_err_print()
    }
    @cpython.py_err_clear()
    return None
  }
  let c = PyObjectEnum::create_by_ref(f)
  Some(c)
}

///|
pub fn PyObject::get_attr(
  self : PyObject,
  attr : String,
) -> PyObjectEnum raise PyRuntimeError {
  match self.try_get_attr(attr) {
    Some(obj) => obj
    None => raise AttributeError(self.to_string(), attr)
  }
}

///|
pub impl IsPyObject for PyObject with obj(self) {
  self
}

///|
pub impl Show for PyObject with to_string(self : PyObject) -> String {
  @cpython.py_object_str_h(self.0)
}

///|
pub impl Show for PyObject with output(self : PyObject, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}
