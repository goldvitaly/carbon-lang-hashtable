// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/impl/fail_todo_impl_assoc_const.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/impl/fail_todo_impl_assoc_const.carbon

interface I { let T:! type; }

// CHECK:STDERR: fail_todo_impl_assoc_const.carbon:[[@LINE+3]]:1: error: semantics TODO: `impl of interface with associated constant T` [SemanticsTodo]
// CHECK:STDERR: impl bool as I where .T = bool {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
impl bool as I where .T = bool {}

// CHECK:STDOUT: --- fail_todo_impl_assoc_const.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %I.type: type = facet_type <@I> [template]
// CHECK:STDOUT:   %Self: %I.type = bind_symbolic_name Self, 0 [symbolic]
// CHECK:STDOUT:   %assoc_type: type = assoc_entity_type %I.type, type [template]
// CHECK:STDOUT:   %assoc0: %assoc_type = assoc_entity element0, @I.%T [template]
// CHECK:STDOUT:   %Bool.type: type = fn_type @Bool [template]
// CHECK:STDOUT:   %Bool: %Bool.type = struct_value () [template]
// CHECK:STDOUT:   %.Self: %I.type = bind_symbolic_name .Self [symbolic]
// CHECK:STDOUT:   %.Self.as_wit: <witness> = facet_access_witness %.Self [symbolic]
// CHECK:STDOUT:   %impl.elem0: type = impl_witness_access %.Self.as_wit, element0 [symbolic]
// CHECK:STDOUT:   %I_where.type: type = facet_type <@I where %impl.elem0 = bool> [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [template] {
// CHECK:STDOUT:     .Bool = %import_ref
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .I = %I.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %I.decl: type = interface_decl @I [template = constants.%I.type] {} {}
// CHECK:STDOUT:   impl_decl @impl [template] {} {
// CHECK:STDOUT:     %bool.make_type.loc16_6: init type = call constants.%Bool() [template = bool]
// CHECK:STDOUT:     %.loc16_6.1: type = value_of_initializer %bool.make_type.loc16_6 [template = bool]
// CHECK:STDOUT:     %.loc16_6.2: type = converted %bool.make_type.loc16_6, %.loc16_6.1 [template = bool]
// CHECK:STDOUT:     %I.ref: type = name_ref I, file.%I.decl [template = constants.%I.type]
// CHECK:STDOUT:     %.Self: %I.type = bind_symbolic_name .Self [symbolic = constants.%.Self]
// CHECK:STDOUT:     %.Self.ref: %I.type = name_ref .Self, %.Self [symbolic = constants.%.Self]
// CHECK:STDOUT:     %T.ref: %assoc_type = name_ref T, @I.%assoc0 [template = constants.%assoc0]
// CHECK:STDOUT:     %.Self.as_wit: <witness> = facet_access_witness %.Self.ref [symbolic = constants.%.Self.as_wit]
// CHECK:STDOUT:     %impl.elem0: type = impl_witness_access %.Self.as_wit, element0 [symbolic = constants.%impl.elem0]
// CHECK:STDOUT:     %bool.make_type.loc16_27: init type = call constants.%Bool() [template = bool]
// CHECK:STDOUT:     %.loc16_27.1: type = value_of_initializer %bool.make_type.loc16_27 [template = bool]
// CHECK:STDOUT:     %.loc16_27.2: type = converted %bool.make_type.loc16_27, %.loc16_27.1 [template = bool]
// CHECK:STDOUT:     %.loc16_16: type = where_expr %.Self [template = constants.%I_where.type] {
// CHECK:STDOUT:       requirement_rewrite %impl.elem0, %.loc16_27.2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: interface @I {
// CHECK:STDOUT:   %Self: %I.type = bind_symbolic_name Self, 0 [symbolic = constants.%Self]
// CHECK:STDOUT:   %T: type = assoc_const_decl T [template]
// CHECK:STDOUT:   %assoc0: %assoc_type = assoc_entity element0, %T [template = constants.%assoc0]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .T = %assoc0
// CHECK:STDOUT:   witness = (%T)
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: impl @impl: %.loc16_6.2 as %.loc16_16 {
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   witness = <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
