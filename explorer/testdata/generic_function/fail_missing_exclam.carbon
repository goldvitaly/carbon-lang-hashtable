// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// NOAUTOUPDATE

package ExplorerTest api;

// CHECK:STDERR: SYNTAX ERROR: fail_missing_exclam.carbon:[[@LINE+1]]: illegal binding pattern in implicit parameter list
fn F[T: type]();

fn Main() -> i32 {
  return 0;
}
