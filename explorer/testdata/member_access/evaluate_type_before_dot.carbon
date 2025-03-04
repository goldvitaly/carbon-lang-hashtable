// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// NOAUTOUPDATE

package Foo api;

choice Choice { Alternative() }
class Class { fn F(n: i32) -> i32 { return n + 1; } }
interface Interface { fn G[self: Self]() -> Self; }
interface AnotherInterface {}

impl i32 as Interface { fn G[self: i32]() -> i32 { return self + 1; } }
impl i32 as AnotherInterface {}

// TODO: These are intended to be called at compile time. Mark them as
// constexpr once we have syntax for that.
fn GetStruct() -> type { return {.n: i32}; }
fn GetChoice() -> type { return Choice; }
fn GetClass() -> type { return Class; }
fn GetInterface() -> type { return Interface; }
fn GetConstraint() -> type { return Interface & AnotherInterface; }

fn TestStruct() {
  var s: GetStruct() = {.n = 1};
  if (s.(GetStruct().n) == 1) {
    Print("Struct OK");
  }
}

fn TestChoice() {
  var c: GetChoice() = GetChoice().Alternative();
  match (c) {
    case GetChoice().Alternative() => {
      Print("Choice OK");
    }
  }
}

fn TestClass() {
  if (GetClass().F(1) == 2) {
    Print("Class OK");
  }
}

fn TestInterface() {
  var n: i32 = 1;
  if (n.(GetInterface().G)() == 2) {
    Print("Interface OK");
  }
}

fn TestConstraint() {
  var n: i32 = 1;
  if (n.(GetConstraint().G)() == 2) {
    Print("Constraint OK");
  }
}

fn Main() -> i32 {
  TestStruct();
  TestChoice();
  TestClass();
  TestInterface();
  TestConstraint();
  return 0;
}

// CHECK:STDOUT: Struct OK
// CHECK:STDOUT: Choice OK
// CHECK:STDOUT: Class OK
// CHECK:STDOUT: Interface OK
// CHECK:STDOUT: Constraint OK
// CHECK:STDOUT: result: 0
