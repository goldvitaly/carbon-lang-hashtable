// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// NOAUTOUPDATE

package ExplorerTest api;

fn CompareStr(s: String) -> i32 {
  if (s == "str\n") {
    return 0;
  }
  return 1;
}

fn Main() -> i32 {
  return CompareStr("str\n");
}

// CHECK:STDOUT: result: 0
