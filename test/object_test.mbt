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
using @python {
  type PyInteger,
  type PyFloat,
  type PyString,
  type PyList,
  type PyTuple,
  type PyBool,
  type PyDict,
}

///|
test "PyInteger Test" {
  let i = PyInteger::from(42)
  inspect(i, content="42")
  inspect(i.type_name(), content="int")
  assert_eq(i.to_int64(), 42)
  assert_eq(i.to_double(), 42.0)
}

///|
test "PyFloat Test" {
  let f = PyFloat::from(3.5)
  inspect(f, content="3.5")
  inspect(f.type_name(), content="float")
  assert_eq(f.to_double(), 3.5)
}

///|
test "PyBool Test" {
  let t = PyBool::from(true)
  let f = PyBool::from(false)
  let f2 = t.not()
  inspect(t, content="True")
  inspect(f, content="False")
  inspect(t.type_name(), content="bool")
  assert_true(t.is_true())
  assert_true(f.is_false())
  assert_true(f2.is_false())
}

///|
test "PyString Test" {
  let s = PyString::from("hello")
  inspect(s, content="hello")
  inspect(s.type_name(), content="str")
  inspect(PyString::from("one"), content="one")
  inspect(PyString::from("two"), content="two")
  let hw = PyString::from("你好，世界")
  inspect(hw, content="你好，世界")
}

///|
test "PyList Test" {
  let list = PyList::new()
  inspect(list, content="[]")
  assert_eq(list.len(), 0)
  inspect(list.type_name(), content="list")
  let one = PyInteger::from(1)
  let two = PyFloat::from(2.0)
  let three = PyString::from("three")
  list.append(one)
  list.append(two)
  list.append(three)
  assert_eq(list.len(), 3)
  inspect(list, content="[1, 2.0, \'three\']")
  inspect(list.get(0).unwrap(), content="PyInteger(1)")
  inspect(list.get(1).unwrap(), content="PyFloat(2.0)")
  inspect(list.get(2), content="Some(PyString(three))")
  inspect(list.get(3), content="None")
  inspect(list.get(-1), content="None")
  inspect(list[0], content="PyInteger(1)")
  inspect(list[1], content="PyFloat(2.0)")
  inspect(list[2], content="PyString(three)")
  let forty_two = PyInteger::from(42)
  list.set(0, forty_two)
  inspect(list, content="[42, 2.0, \'three\']")
  list[1] = forty_two
  inspect(list, content="[42, 42, \'three\']")
}

///|
test "PyTuple Test" {
  let tuple = PyTuple::new(3)
  tuple
  ..set(0, PyInteger::from(1))
  ..set(1, PyFloat::from(2.0))
  ..set(2, PyString::from("three"))
  inspect(tuple.type_name(), content="tuple")
  assert_eq(tuple.len(), 3)
  inspect(tuple, content="(1, 2.0, \'three\')")
  inspect(tuple.get(0).unwrap(), content="PyInteger(1)")
  inspect(tuple.get(1).unwrap(), content="PyFloat(2.0)")
  inspect(tuple.get(2).unwrap(), content="PyString(three)")
  inspect(tuple.get(3), content="None")
  tuple[0] = PyInteger::from(42)
  inspect(tuple, content="(42, 2.0, \'three\')")
}

///|
test "PyDict Test" {
  let dict = PyDict::new()
  dict
  ..set("one", PyInteger::from(1))
  ..set("two", PyFloat::from(2.0))
  ..set("three", PyBool::from(true))
  inspect(dict.type_name(), content="dict")
  assert_eq(dict.len(), 3)
  inspect(dict, content="{\'one\': 1, \'two\': 2.0, \'three\': True}")
  inspect(dict.get("one").unwrap(), content="PyInteger(1)")
  inspect(dict.get("two"), content="Some(PyFloat(2.0))")
  inspect(dict.get("four"), content="None")
  inspect(dict["one"], content="PyInteger(1)")
  inspect(dict["two"], content="PyFloat(2.0)")
  inspect(dict["three"], content="PyBool(True)")
  inspect(dict.keys(), content="[\'one\', \'two\', \'three\']")
  inspect(dict.values(), content="[1, 2.0, True]")
  let dict = PyDict::new()
  dict
  ..setByObj(PyInteger::from(1), PyInteger::from(1))
  ..setByObj(PyInteger::from(2), PyInteger::from(4))
  ..setByObj(PyInteger::from(3), PyInteger::from(9))
  inspect(dict, content="{1: 1, 2: 4, 3: 9}")
  let list = PyList::new()
  list..append(PyInteger::from(3))..append(PyInteger::from(2))
  let e = try? dict.setByObj(list, PyInteger::from(42))
  inspect(e, content="Err(KeyIsUnHashableError)")
}

///|
/// This test demonstrates the RC bug in PyList::set().
/// PyList_SetItem() steals the reference, but the MoonBit wrapper
/// still holds it. When we call drop(), it will DECREF an already
/// stolen reference, causing a double-free.
test "RC Bug - PyList set steals reference" {
  let list = PyList::new()
  list.append(PyString::from("placeholder"))

  // Use a string (not cached like small integers)
  let item = PyString::from("unique_string_not_cached_12345")
  list.set(0, item) // PyList_SetItem steals reference

  // Now: list owns the ref, but `item` still thinks it owns it too
  // This causes a double-decref when we explicitly drop
  item.drop() // BOOM: double-decref on already-stolen ref

  // If we get here, the memory is corrupted
  let _ = list[0].to_string()
}

///|
/// This test demonstrates the RC bug in PyList::get().
/// PyList_GetItem() returns a borrowed reference, but we wrap it
/// as owned without INCREF. When the original is freed, we have a
/// dangling pointer.
test "RC Bug - PyList get borrowed reference" {
  let list = PyList::new()
  // Use unique string to avoid Python string interning
  list.append(PyString::from("unique_list_get_test_string_12345"))

  let item = list.get(0).unwrap() // Borrowed ref, no INCREF

  // Force the original string to be freed by replacing it
  list.set(0, PyString::from("replacement_string"))

  // Trigger use-after-free by accessing the freed memory
  // Need to force memory reuse to make ASan detect it
  for i in 0..<100 {
    let _ = PyString::from("allocate_\{i}_to_reuse_memory")
  }

  // Access the dangling pointer - should trigger ASan
  let _ = item.to_string()
}

///|
/// This test demonstrates the RC bug in PyTuple::set().
/// PyTuple_SetItem() steals the reference, but the MoonBit wrapper
/// still holds it. When we call drop(), it will DECREF an already
/// stolen reference.
test "RC Bug - PyTuple set steals reference" {
  let tuple = PyTuple::new(1)
  tuple.set(0, PyString::from("placeholder"))

  let item = PyString::from("unique_tuple_set_string_67890")
  tuple.set(0, item) // PyTuple_SetItem steals reference
  item.drop() // BOOM: double-decref on stolen ref

  let _ = tuple[0].to_string()
}

///|
/// This test demonstrates the RC bug in PyTuple::get().
/// PyTuple_GetItem() returns a borrowed reference, but we wrap it
/// as owned without INCREF.
test "RC Bug - PyTuple get borrowed reference" {
  let tuple = PyTuple::new(1)
  tuple.set(0, PyString::from("unique_tuple_get_string_11111"))

  let item = tuple.get(0).unwrap() // Borrowed ref
  tuple.set(0, PyString::from("replacement")) // Replace - original freed

  for i in 0..<100 {
    let _ = PyString::from("force_reuse_\{i}")
  }

  let _ = item.to_string() // Use-after-free
}

///|
/// This test demonstrates the RC bug in PyDict::get().
/// PyDict_GetItemString() returns a borrowed reference, but we wrap it
/// as owned without INCREF.
test "RC Bug - PyDict get borrowed reference" {
  let dict = PyDict::new()
  dict.set("key", PyString::from("unique_dict_get_value_22222"))

  let item = dict.get("key").unwrap() // Borrowed ref
  dict.set("key", PyString::from("replacement")) // Replace - original freed

  for i in 0..<100 {
    let _ = PyString::from("force_reuse_\{i}")
  }

  let _ = item.to_string() // Use-after-free
}
