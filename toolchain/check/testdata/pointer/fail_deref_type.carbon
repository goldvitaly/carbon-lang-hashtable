// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/pointer/fail_deref_type.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/pointer/fail_deref_type.carbon

// CHECK:STDERR: fail_deref_type.carbon:[[@LINE+7]]:8: error: cannot dereference operand of non-pointer type `type` [DerefOfNonPointer]
// CHECK:STDERR: var p: *i32;
// CHECK:STDERR:        ^
// CHECK:STDERR: fail_deref_type.carbon:[[@LINE+4]]:8: note: to form a pointer type, write the `*` after the pointee type [DerefOfType]
// CHECK:STDERR: var p: *i32;
// CHECK:STDERR:        ^
// CHECK:STDERR:
var p: *i32;
// CHECK:STDERR: fail_deref_type.carbon:[[@LINE+3]]:12: error: cannot apply `->` operator to non-pointer type `type` [ArrowOperatorOfNonPointer]
// CHECK:STDERR: var p2: i32->foo;
// CHECK:STDERR:            ^~
var p2: i32->foo;

// CHECK:STDOUT: --- fail_deref_type.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [template] {
// CHECK:STDOUT:     .Int = %import_ref.1
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .p = %p
// CHECK:STDOUT:     .p2 = %p2
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %p.var: ref <error> = var p
// CHECK:STDOUT:   %p: ref <error> = bind_name p, %p.var
// CHECK:STDOUT:   %p2.var: ref <error> = var p2
// CHECK:STDOUT:   %p2: ref <error> = bind_name p2, %p2.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
