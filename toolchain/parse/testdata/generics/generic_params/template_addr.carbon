// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/generics/generic_params/template_addr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/generics/generic_params/template_addr.carbon

fn foo(template addr a:! i32);

// CHECK:STDOUT: - filename: template_addr.carbon
// CHECK:STDOUT:   parse_tree: [
// CHECK:STDOUT:     {kind: 'FileStart', text: ''},
// CHECK:STDOUT:       {kind: 'FunctionIntroducer', text: 'fn'},
// CHECK:STDOUT:       {kind: 'IdentifierName', text: 'foo'},
// CHECK:STDOUT:         {kind: 'TuplePatternStart', text: '('},
// CHECK:STDOUT:               {kind: 'IdentifierName', text: 'a'},
// CHECK:STDOUT:               {kind: 'IntTypeLiteral', text: 'i32'},
// CHECK:STDOUT:             {kind: 'CompileTimeBindingPattern', text: ':!', subtree_size: 3},
// CHECK:STDOUT:           {kind: 'Addr', text: 'addr', subtree_size: 4},
// CHECK:STDOUT:         {kind: 'Template', text: 'template', subtree_size: 5},
// CHECK:STDOUT:       {kind: 'TuplePattern', text: ')', subtree_size: 7},
// CHECK:STDOUT:     {kind: 'FunctionDecl', text: ';', subtree_size: 10},
// CHECK:STDOUT:     {kind: 'FileEnd', text: ''},
// CHECK:STDOUT:   ]
