// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// NOAUTOUPDATE

package ExplorerTest api;

base class C {
}

class D {
  extend base: C;
  impl fn Foo[self:Self]() -> i32 {
    return 1;
  // CHECK:STDERR: COMPILATION ERROR: fail_impl_method_not_existing.carbon:[[@LINE+1]]: Error declaring `Foo`: cannot override a method that is not declared `abstract` or `virtual` in base class.
  }
}

fn Main() -> i32 {
  let d: D = {};
  return 0;
}
