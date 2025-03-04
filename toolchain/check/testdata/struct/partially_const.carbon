// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/struct/partially_const.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/struct/partially_const.carbon

fn Make(n: i32) -> {.a: i32, .b: i32, .c: i32} {
  return {.a = 0, .b = n, .c = 0};
}

// CHECK:STDOUT: --- partially_const.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [template]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [template]
// CHECK:STDOUT:   %struct_type.a.b.c.1: type = struct_type {.a: %i32, .b: %i32, .c: %i32} [template]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [template]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [template]
// CHECK:STDOUT:   %int_0.1: Core.IntLiteral = int_value 0 [template]
// CHECK:STDOUT:   %struct_type.a.b.c.2: type = struct_type {.a: Core.IntLiteral, .b: %i32, .c: Core.IntLiteral} [template]
// CHECK:STDOUT:   %Convert.type.2: type = fn_type @Convert.1, @ImplicitAs(%i32) [template]
// CHECK:STDOUT:   %impl_witness.19: <witness> = impl_witness (imports.%import_ref.14), @impl.1(%int_32) [template]
// CHECK:STDOUT:   %Convert.type.10: type = fn_type @Convert.2, @impl.1(%int_32) [template]
// CHECK:STDOUT:   %Convert.10: %Convert.type.10 = struct_value () [template]
// CHECK:STDOUT:   %Convert.bound: <bound method> = bound_method %int_0.1, %Convert.10 [template]
// CHECK:STDOUT:   %Convert.specific_fn: <specific function> = specific_function %Convert.bound, @Convert.2(%int_32) [template]
// CHECK:STDOUT:   %int_0.2: %i32 = int_value 0 [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [template] {
// CHECK:STDOUT:     .Int = %import_ref.1
// CHECK:STDOUT:     .ImplicitAs = %import_ref.5
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Make = %Make.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [template = constants.%Make] {
// CHECK:STDOUT:     %n.patt: %i32 = binding_pattern n
// CHECK:STDOUT:     %n.param_patt: %i32 = value_param_pattern %n.patt, runtime_param0
// CHECK:STDOUT:     %return.patt: %struct_type.a.b.c.1 = return_slot_pattern
// CHECK:STDOUT:     %return.param_patt: %struct_type.a.b.c.1 = out_param_pattern %return.patt, runtime_param1
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %int_32.loc11_25: Core.IntLiteral = int_value 32 [template = constants.%int_32]
// CHECK:STDOUT:     %i32.loc11_25: type = class_type @Int, @Int(constants.%int_32) [template = constants.%i32]
// CHECK:STDOUT:     %int_32.loc11_34: Core.IntLiteral = int_value 32 [template = constants.%int_32]
// CHECK:STDOUT:     %i32.loc11_34: type = class_type @Int, @Int(constants.%int_32) [template = constants.%i32]
// CHECK:STDOUT:     %int_32.loc11_43: Core.IntLiteral = int_value 32 [template = constants.%int_32]
// CHECK:STDOUT:     %i32.loc11_43: type = class_type @Int, @Int(constants.%int_32) [template = constants.%i32]
// CHECK:STDOUT:     %struct_type.a.b.c: type = struct_type {.a: %i32, .b: %i32, .c: %i32} [template = constants.%struct_type.a.b.c.1]
// CHECK:STDOUT:     %n.param: %i32 = value_param runtime_param0
// CHECK:STDOUT:     %.loc11: type = splice_block %i32.loc11_12 [template = constants.%i32] {
// CHECK:STDOUT:       %int_32.loc11_12: Core.IntLiteral = int_value 32 [template = constants.%int_32]
// CHECK:STDOUT:       %i32.loc11_12: type = class_type @Int, @Int(constants.%int_32) [template = constants.%i32]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %n: %i32 = bind_name n, %n.param
// CHECK:STDOUT:     %return.param: ref %struct_type.a.b.c.1 = out_param runtime_param1
// CHECK:STDOUT:     %return: ref %struct_type.a.b.c.1 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make(%n.param_patt: %i32) -> %return.param_patt: %struct_type.a.b.c.1 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0.loc12_16: Core.IntLiteral = int_value 0 [template = constants.%int_0.1]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_0.loc12_32: Core.IntLiteral = int_value 0 [template = constants.%int_0.1]
// CHECK:STDOUT:   %.loc12_33.1: %struct_type.a.b.c.2 = struct_literal (%int_0.loc12_16, %n.ref, %int_0.loc12_32)
// CHECK:STDOUT:   %impl.elem0.loc12_33.1: %Convert.type.2 = impl_witness_access constants.%impl_witness.19, element0 [template = constants.%Convert.10]
// CHECK:STDOUT:   %Convert.bound.loc12_33.1: <bound method> = bound_method %int_0.loc12_16, %impl.elem0.loc12_33.1 [template = constants.%Convert.bound]
// CHECK:STDOUT:   %Convert.specific_fn.loc12_33.1: <specific function> = specific_function %Convert.bound.loc12_33.1, @Convert.2(constants.%int_32) [template = constants.%Convert.specific_fn]
// CHECK:STDOUT:   %int.convert_checked.loc12_33.1: init %i32 = call %Convert.specific_fn.loc12_33.1(%int_0.loc12_16) [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.2: init %i32 = converted %int_0.loc12_16, %int.convert_checked.loc12_33.1 [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.3: ref %i32 = struct_access %return, element0
// CHECK:STDOUT:   %.loc12_33.4: init %i32 = initialize_from %.loc12_33.2 to %.loc12_33.3 [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.5: ref %i32 = struct_access %return, element1
// CHECK:STDOUT:   %.loc12_33.6: init %i32 = initialize_from %n.ref to %.loc12_33.5
// CHECK:STDOUT:   %impl.elem0.loc12_33.2: %Convert.type.2 = impl_witness_access constants.%impl_witness.19, element0 [template = constants.%Convert.10]
// CHECK:STDOUT:   %Convert.bound.loc12_33.2: <bound method> = bound_method %int_0.loc12_32, %impl.elem0.loc12_33.2 [template = constants.%Convert.bound]
// CHECK:STDOUT:   %Convert.specific_fn.loc12_33.2: <specific function> = specific_function %Convert.bound.loc12_33.2, @Convert.2(constants.%int_32) [template = constants.%Convert.specific_fn]
// CHECK:STDOUT:   %int.convert_checked.loc12_33.2: init %i32 = call %Convert.specific_fn.loc12_33.2(%int_0.loc12_32) [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.7: init %i32 = converted %int_0.loc12_32, %int.convert_checked.loc12_33.2 [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.8: ref %i32 = struct_access %return, element2
// CHECK:STDOUT:   %.loc12_33.9: init %i32 = initialize_from %.loc12_33.7 to %.loc12_33.8 [template = constants.%int_0.2]
// CHECK:STDOUT:   %.loc12_33.10: init %struct_type.a.b.c.1 = struct_init (%.loc12_33.4, %.loc12_33.6, %.loc12_33.9) to %return
// CHECK:STDOUT:   %.loc12_34: init %struct_type.a.b.c.1 = converted %.loc12_33.1, %.loc12_33.10
// CHECK:STDOUT:   return %.loc12_34 to %return
// CHECK:STDOUT: }
// CHECK:STDOUT:
