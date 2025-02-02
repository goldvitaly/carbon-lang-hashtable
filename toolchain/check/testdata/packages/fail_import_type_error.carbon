// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/packages/fail_import_type_error.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/packages/fail_import_type_error.carbon

// --- fail_implicit.carbon

package Implicit;

// CHECK:STDERR: fail_implicit.carbon:[[@LINE+4]]:12: error: name `x` not found [NameNotFound]
// CHECK:STDERR: var a_ref: x;
// CHECK:STDERR:            ^
// CHECK:STDERR:
var a_ref: x;
// CHECK:STDERR: fail_implicit.carbon:[[@LINE+4]]:18: error: name `x` not found [NameNotFound]
// CHECK:STDERR: var b_ref: {.a = x};
// CHECK:STDERR:                  ^
// CHECK:STDERR:
var b_ref: {.a = x};
// CHECK:STDERR: fail_implicit.carbon:[[@LINE+4]]:13: error: name `x` not found [NameNotFound]
// CHECK:STDERR: var c_ref: (x,);
// CHECK:STDERR:             ^
// CHECK:STDERR:
var c_ref: (x,);
// CHECK:STDERR: fail_implicit.carbon:[[@LINE+3]]:12: error: name `x` not found [NameNotFound]
// CHECK:STDERR: var d_ref: x*;
// CHECK:STDERR:            ^
var d_ref: x*;

// --- implicit.impl.carbon

impl package Implicit;

// In each of these cases, name lookup should succeed, but they should all have
// an error type.
var a: i32 = a_ref;
var b: i32 = b_ref;
var c: i32 = c_ref;
var d: i32 = d_ref;

// CHECK:STDOUT: --- fail_implicit.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [template] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .a_ref = %a_ref
// CHECK:STDOUT:     .b_ref = %b_ref
// CHECK:STDOUT:     .c_ref = %c_ref
// CHECK:STDOUT:     .d_ref = %d_ref
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %a_ref.var: ref <error> = var a_ref
// CHECK:STDOUT:   %a_ref: ref <error> = bind_name a_ref, %a_ref.var
// CHECK:STDOUT:   %b_ref.var: ref <error> = var b_ref
// CHECK:STDOUT:   %b_ref: ref <error> = bind_name b_ref, %b_ref.var
// CHECK:STDOUT:   %c_ref.var: ref <error> = var c_ref
// CHECK:STDOUT:   %c_ref: ref <error> = bind_name c_ref, %c_ref.var
// CHECK:STDOUT:   %d_ref.var: ref <error> = var d_ref
// CHECK:STDOUT:   %d_ref: ref <error> = bind_name d_ref, %d_ref.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- implicit.impl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [template]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %import_ref.1: ref <error> = import_ref Implicit//default, a_ref, loaded
// CHECK:STDOUT:   %import_ref.2: ref <error> = import_ref Implicit//default, b_ref, loaded
// CHECK:STDOUT:   %import_ref.3: ref <error> = import_ref Implicit//default, c_ref, loaded
// CHECK:STDOUT:   %import_ref.4: ref <error> = import_ref Implicit//default, d_ref, loaded
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [template] {
// CHECK:STDOUT:     .Int = %import_ref.5
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .a_ref = imports.%import_ref.1
// CHECK:STDOUT:     .b_ref = imports.%import_ref.2
// CHECK:STDOUT:     .c_ref = imports.%import_ref.3
// CHECK:STDOUT:     .d_ref = imports.%import_ref.4
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .a = %a
// CHECK:STDOUT:     .b = %b
// CHECK:STDOUT:     .c = %c
// CHECK:STDOUT:     .d = %d
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Implicit.import = import Implicit
// CHECK:STDOUT:   %default.import = import <invalid>
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %a.var: ref %i32 = var a
// CHECK:STDOUT:   %a: ref %i32 = bind_name a, %a.var
// CHECK:STDOUT:   %b.var: ref %i32 = var b
// CHECK:STDOUT:   %b: ref %i32 = bind_name b, %b.var
// CHECK:STDOUT:   %c.var: ref %i32 = var c
// CHECK:STDOUT:   %c: ref %i32 = bind_name c, %c.var
// CHECK:STDOUT:   %d.var: ref %i32 = var d
// CHECK:STDOUT:   %d: ref %i32 = bind_name d, %d.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a_ref.ref: ref <error> = name_ref a_ref, imports.%import_ref.1
// CHECK:STDOUT:   assign file.%a.var, <error>
// CHECK:STDOUT:   %b_ref.ref: ref <error> = name_ref b_ref, imports.%import_ref.2
// CHECK:STDOUT:   assign file.%b.var, <error>
// CHECK:STDOUT:   %c_ref.ref: ref <error> = name_ref c_ref, imports.%import_ref.3
// CHECK:STDOUT:   assign file.%c.var, <error>
// CHECK:STDOUT:   %d_ref.ref: ref <error> = name_ref d_ref, imports.%import_ref.4
// CHECK:STDOUT:   assign file.%d.var, <error>
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
