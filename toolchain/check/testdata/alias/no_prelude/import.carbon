// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/alias/no_prelude/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/alias/no_prelude/import.carbon

// --- class1.carbon

library "[[@TEST_NAME]]";

class C {}

alias c_alias = C;

var a: C*;

// --- class2.carbon

library "[[@TEST_NAME]]";

import library "class1";

alias c_alias_alias = c_alias;

var b: c_alias*;

// --- class3.carbon

library "[[@TEST_NAME]]";

import library "class2";

var c: c_alias_alias*;

// --- var1.carbon

library "[[@TEST_NAME]]";

var a: () = ();

alias a_alias = a;

// --- var2.carbon

library "[[@TEST_NAME]]";

import library "var1";

alias a_alias_alias = a_alias;

var b: () = a_alias;

// --- fail_var3.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_var3.carbon:[[@LINE+4]]:1: in import [InImport]
// CHECK:STDERR: var2.carbon:8:5: error: semantics TODO: `Non-constant ImportRefLoaded (comes up with var)` [SemanticsTodo]
// CHECK:STDERR: var b: () = a_alias;
// CHECK:STDERR:     ^
import library "var2";

var c: () = a_alias_alias;

// CHECK:STDOUT: --- class1.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %C: type = class_type @C [template]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [template]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [template]
// CHECK:STDOUT:   %ptr: type = ptr_type %C [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .C = %C.decl
// CHECK:STDOUT:     .c_alias = %c_alias
// CHECK:STDOUT:     .a = %a
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %C.decl: type = class_decl @C [template = constants.%C] {} {}
// CHECK:STDOUT:   %C.ref: type = name_ref C, %C.decl [template = constants.%C]
// CHECK:STDOUT:   %c_alias: type = bind_alias c_alias, %C.decl [template = constants.%C]
// CHECK:STDOUT:   %a.var: ref %ptr = var a
// CHECK:STDOUT:   %a: ref %ptr = bind_name a, %a.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [template = constants.%complete_type]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%C
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class2.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %C: type = class_type @C [template]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [template]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [template]
// CHECK:STDOUT:   %ptr: type = ptr_type %C [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %import_ref.1 = import_ref Main//class1, C, unloaded
// CHECK:STDOUT:   %import_ref.2: type = import_ref Main//class1, c_alias, loaded [template = constants.%C]
// CHECK:STDOUT:   %import_ref.3 = import_ref Main//class1, a, unloaded
// CHECK:STDOUT:   %import_ref.4: <witness> = import_ref Main//class1, loc4_10, loaded [template = constants.%complete_type]
// CHECK:STDOUT:   %import_ref.5 = import_ref Main//class1, inst14 [no loc], unloaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .C = imports.%import_ref.1
// CHECK:STDOUT:     .c_alias = imports.%import_ref.2
// CHECK:STDOUT:     .a = imports.%import_ref.3
// CHECK:STDOUT:     .c_alias_alias = %c_alias_alias
// CHECK:STDOUT:     .b = %b
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %default.import = import <invalid>
// CHECK:STDOUT:   %c_alias.ref: type = name_ref c_alias, imports.%import_ref.2 [template = constants.%C]
// CHECK:STDOUT:   %c_alias_alias: type = bind_alias c_alias_alias, imports.%import_ref.2 [template = constants.%C]
// CHECK:STDOUT:   %b.var: ref %ptr = var b
// CHECK:STDOUT:   %b: ref %ptr = bind_name b, %b.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C [from "class1.carbon"] {
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = imports.%import_ref.5
// CHECK:STDOUT:   complete_type_witness = imports.%import_ref.4
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class3.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %C: type = class_type @C [template]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [template]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [template]
// CHECK:STDOUT:   %ptr: type = ptr_type %C [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %import_ref.1: type = import_ref Main//class2, c_alias_alias, loaded [template = constants.%C]
// CHECK:STDOUT:   %import_ref.2 = import_ref Main//class2, b, unloaded
// CHECK:STDOUT:   %import_ref.3: <witness> = import_ref Main//class2, inst21 [indirect], loaded [template = constants.%complete_type]
// CHECK:STDOUT:   %import_ref.4 = import_ref Main//class2, inst22 [indirect], unloaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .c_alias_alias = imports.%import_ref.1
// CHECK:STDOUT:     .b = imports.%import_ref.2
// CHECK:STDOUT:     .c = %c
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %default.import = import <invalid>
// CHECK:STDOUT:   %c.var: ref %ptr = var c
// CHECK:STDOUT:   %c: ref %ptr = bind_name c, %c.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C [from "class2.carbon"] {
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = imports.%import_ref.4
// CHECK:STDOUT:   complete_type_witness = imports.%import_ref.3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var1.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [template]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .a = %a
// CHECK:STDOUT:     .a_alias = %a_alias
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %a.var: ref %empty_tuple.type = var a
// CHECK:STDOUT:   %a: ref %empty_tuple.type = bind_name a, %a.var
// CHECK:STDOUT:   %a.ref: ref %empty_tuple.type = name_ref a, %a
// CHECK:STDOUT:   %a_alias: ref %empty_tuple.type = bind_alias a_alias, %a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_14.1: %empty_tuple.type = tuple_literal ()
// CHECK:STDOUT:   %.loc4_14.2: init %empty_tuple.type = tuple_init () to file.%a.var [template = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc4_15: init %empty_tuple.type = converted %.loc4_14.1, %.loc4_14.2 [template = constants.%empty_tuple]
// CHECK:STDOUT:   assign file.%a.var, %.loc4_15
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var2.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [template]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %import_ref.1 = import_ref Main//var1, a, unloaded
// CHECK:STDOUT:   %import_ref.2: ref %empty_tuple.type = import_ref Main//var1, a_alias, loaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .a = imports.%import_ref.1
// CHECK:STDOUT:     .a_alias = imports.%import_ref.2
// CHECK:STDOUT:     .a_alias_alias = %a_alias_alias
// CHECK:STDOUT:     .b = %b
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %default.import = import <invalid>
// CHECK:STDOUT:   %a_alias.ref: ref %empty_tuple.type = name_ref a_alias, imports.%import_ref.2
// CHECK:STDOUT:   %a_alias_alias: ref %empty_tuple.type = bind_alias a_alias_alias, imports.%import_ref.2
// CHECK:STDOUT:   %b.var: ref %empty_tuple.type = var b
// CHECK:STDOUT:   %b: ref %empty_tuple.type = bind_name b, %b.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a_alias.ref: ref %empty_tuple.type = name_ref a_alias, imports.%import_ref.2
// CHECK:STDOUT:   %.loc8_13: init %empty_tuple.type = tuple_init () to file.%b.var [template = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc8_20: init %empty_tuple.type = converted %a_alias.ref, %.loc8_13 [template = constants.%empty_tuple]
// CHECK:STDOUT:   assign file.%b.var, %.loc8_20
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- fail_var3.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [template]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %import_ref.1: ref %empty_tuple.type = import_ref Main//var2, a_alias_alias, loaded [template = <error>]
// CHECK:STDOUT:   %import_ref.2 = import_ref Main//var2, b, unloaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [template] {
// CHECK:STDOUT:     .a_alias_alias = imports.%import_ref.1
// CHECK:STDOUT:     .b = imports.%import_ref.2
// CHECK:STDOUT:     .c = %c
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %default.import = import <invalid>
// CHECK:STDOUT:   %c.var: ref %empty_tuple.type = var c
// CHECK:STDOUT:   %c: ref %empty_tuple.type = bind_name c, %c.var
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a_alias_alias.ref: ref %empty_tuple.type = name_ref a_alias_alias, imports.%import_ref.1 [template = <error>]
// CHECK:STDOUT:   %.loc10_13: init %empty_tuple.type = tuple_init () to file.%c.var [template = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_26: init %empty_tuple.type = converted %a_alias_alias.ref, %.loc10_13 [template = constants.%empty_tuple]
// CHECK:STDOUT:   assign file.%c.var, %.loc10_26
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
