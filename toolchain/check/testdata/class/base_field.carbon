// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/class/base_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/class/base_field.carbon

base class Base {
  var a: i32;
  var b: i32;
  var c: i32;
}

class Derived {
  extend base: Base;

  var d: i32;
  var e: i32;
}

fn Access(p: Derived*) -> i32* {
  return &(*p).c;
}

// CHECK:STDOUT: --- base_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Base: type = class_type @Base [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [template]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [template]
// CHECK:STDOUT:   %Base.elem: type = unbound_element_type %Base, %i32 [template]
// CHECK:STDOUT:   %struct_type.a.b.c: type = struct_type {.a: %i32, .b: %i32, .c: %i32} [template]
// CHECK:STDOUT:   %complete_type.3: <witness> = complete_type_witness %struct_type.a.b.c [template]
// CHECK:STDOUT:   %Derived: type = class_type @Derived [template]
// CHECK:STDOUT:   %Derived.elem.1: type = unbound_element_type %Derived, %Base [template]
// CHECK:STDOUT:   %Derived.elem.2: type = unbound_element_type %Derived, %i32 [template]
// CHECK:STDOUT:   %struct_type.base.d.e.1: type = struct_type {.base: %Base, .d: %i32, .e: %i32} [template]
// CHECK:STDOUT:   %complete_type.4: <witness> = complete_type_witness %struct_type.base.d.e.1 [template]
// CHECK:STDOUT:   %ptr.2: type = ptr_type %Derived [template]
// CHECK:STDOUT:   %ptr.3: type = ptr_type %i32 [template]
// CHECK:STDOUT:   %Access.type: type = fn_type @Access [template]
// CHECK:STDOUT:   %Access: %Access.type = struct_value () [template]
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
// CHECK:STDOUT:     .Base = %Base.decl
// CHECK:STDOUT:     .Derived = %Derived.decl
// CHECK:STDOUT:     .Access = %Access.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Base.decl: type = class_decl @Base [template = constants.%Base] {} {}
// CHECK:STDOUT:   %Derived.decl: type = class_decl @Derived [template = constants.%Derived] {} {}
// CHECK:STDOUT:   %Access.decl: %Access.type = fn_decl @Access [template = constants.%Access] {
// CHECK:STDOUT:     %p.patt: %ptr.2 = binding_pattern p
// CHECK:STDOUT:     %p.param_patt: %ptr.2 = value_param_pattern %p.patt, runtime_param0
// CHECK:STDOUT:     %return.patt: %ptr.3 = return_slot_pattern
// CHECK:STDOUT:     %return.param_patt: %ptr.3 = out_param_pattern %return.patt, runtime_param1
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %int_32: Core.IntLiteral = int_value 32 [template = constants.%int_32]
// CHECK:STDOUT:     %i32: type = class_type @Int, @Int(constants.%int_32) [template = constants.%i32]
// CHECK:STDOUT:     %ptr.loc24_30: type = ptr_type %i32 [template = constants.%ptr.3]
// CHECK:STDOUT:     %p.param: %ptr.2 = value_param runtime_param0
// CHECK:STDOUT:     %.loc24: type = splice_block %ptr.loc24_21 [template = constants.%ptr.2] {
// CHECK:STDOUT:       %Derived.ref: type = name_ref Derived, file.%Derived.decl [template = constants.%Derived]
// CHECK:STDOUT:       %ptr.loc24_21: type = ptr_type %Derived [template = constants.%ptr.2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.2 = bind_name p, %p.param
// CHECK:STDOUT:     %return.param: ref %ptr.3 = out_param runtime_param1
// CHECK:STDOUT:     %return: ref %ptr.3 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Base {
// CHECK:STDOUT:   %.loc12: %Base.elem = field_decl a, element0 [template]
// CHECK:STDOUT:   %.loc13: %Base.elem = field_decl b, element1 [template]
// CHECK:STDOUT:   %.loc14: %Base.elem = field_decl c, element2 [template]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %struct_type.a.b.c [template = constants.%complete_type.3]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Base
// CHECK:STDOUT:   .a = %.loc12
// CHECK:STDOUT:   .b = %.loc13
// CHECK:STDOUT:   .c = %.loc14
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Derived {
// CHECK:STDOUT:   %Base.ref: type = name_ref Base, file.%Base.decl [template = constants.%Base]
// CHECK:STDOUT:   %.loc18: %Derived.elem.1 = base_decl %Base.ref, element0 [template]
// CHECK:STDOUT:   %.loc20: %Derived.elem.2 = field_decl d, element1 [template]
// CHECK:STDOUT:   %.loc21: %Derived.elem.2 = field_decl e, element2 [template]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %struct_type.base.d.e.1 [template = constants.%complete_type.4]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Derived
// CHECK:STDOUT:   .base = %.loc18
// CHECK:STDOUT:   .d = %.loc20
// CHECK:STDOUT:   .e = %.loc21
// CHECK:STDOUT:   extend %Base.ref
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Access(%p.param_patt: %ptr.2) -> %ptr.3 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %ptr.2 = name_ref p, %p
// CHECK:STDOUT:   %.loc25_12: ref %Derived = deref %p.ref
// CHECK:STDOUT:   %c.ref: %Base.elem = name_ref c, @Base.%.loc14 [template = @Base.%.loc14]
// CHECK:STDOUT:   %.loc25_15.1: ref %Base = class_element_access %.loc25_12, element0
// CHECK:STDOUT:   %.loc25_15.2: ref %Base = converted %.loc25_12, %.loc25_15.1
// CHECK:STDOUT:   %.loc25_15.3: ref %i32 = class_element_access %.loc25_15.2, element2
// CHECK:STDOUT:   %addr: %ptr.3 = addr_of %.loc25_15.3
// CHECK:STDOUT:   return %addr
// CHECK:STDOUT: }
// CHECK:STDOUT:
