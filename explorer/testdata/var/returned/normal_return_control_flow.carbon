// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// NOAUTOUPDATE

package ExplorerTest api;

fn AddInt(a: i32, b: i32) -> i32 {
  if (a == b) {
    returned var ret: i32 = a + b;
    return var;
  } else {
    return a + b;
  }
}

fn Main() -> i32 {
  return AddInt(1, 2);
}

// CHECK:STDOUT: result: 3
