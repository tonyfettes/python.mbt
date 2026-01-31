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
pub struct Screen {
  priv screen : PyObject
}

///|
pub fn Screen::new() -> Screen raise @python.PyRuntimeError {
  let lib = singleton()
  guard lib.turtle.get_attr("Screen") is Some(PyCallable(createScreen))
  guard createScreen.invoke() is Some(PyClass(screen))
  Screen::{ screen, }
}

///|
pub fn Screen::setup(
  self : Screen,
  width : Double,
  height : Double
) -> Unit raise @python.PyRuntimeError {
  guard self.screen.get_attr("setup") is Some(PyCallable(setup))
  let args = PyTuple::new(2)
  args..set(0, PyFloat::from(width))..set(1, PyFloat::from(height))
  let _ = setup.invoke(args~)

}

///|
pub fn Screen::title(self : Screen, text : String) -> Unit raise @python.PyRuntimeError {
  guard self.screen.get_attr("title") is Some(PyCallable(title))
  let args = PyTuple::new(1)
  args..set(0, PyString::from(text))
  let _ = title.invoke(args~)

}

///|
pub fn Screen::tracer(self : Screen, n : Int) -> Unit raise @python.PyRuntimeError {
  guard self.screen.get_attr("tracer") is Some(PyCallable(tracer))
  let args = PyTuple::new(1)
  args..set(0, PyInteger::from(n.to_int64()))
  let _ = tracer.invoke(args~)

}

///|
pub fn Screen::update(self : Screen) -> Unit raise @python.PyRuntimeError {
  guard self.screen.get_attr("update") is Some(PyCallable(update))
  let _ = update.invoke()

}

///|
pub fn Screen::bgcolor(self : Screen, color : Color) -> Unit raise @python.PyRuntimeError {
  guard self.screen.get_attr("bgcolor") is Some(PyCallable(bgcolor))
  let args = PyTuple::new(1)
  args..set(0, PyString::from(color.to_string()))
  let _ = bgcolor.invoke(args~)

}
