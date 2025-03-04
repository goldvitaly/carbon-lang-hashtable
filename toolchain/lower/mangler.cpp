// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/lower/mangler.h"

#include "toolchain/base/kind_switch.h"
#include "toolchain/sem_ir/entry_point.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Lower {

auto Mangler::MangleInverseQualifiedNameScope(llvm::raw_ostream& os,
                                              SemIR::NameScopeId name_scope_id)
    -> void {
  // Maintain a stack of names for delayed rendering of interface impls.
  struct NameEntry {
    SemIR::NameScopeId name_scope_id;

    // The prefix emitted before this name component. If '\0', no prefix will be
    // emitted.
    // - Namespace components are separated by '.'.
    // - The two components of an interface are separated by ':'.
    char prefix;
  };
  llvm::SmallVector<NameEntry> names_to_render;
  names_to_render.push_back({.name_scope_id = name_scope_id, .prefix = '.'});
  while (!names_to_render.empty()) {
    auto [name_scope_id, prefix] = names_to_render.pop_back_val();
    if (prefix) {
      os << prefix;
    }
    if (name_scope_id == SemIR::NameScopeId::Package) {
      if (auto package_id = sem_ir().package_id(); package_id.is_valid()) {
        os << sem_ir().identifiers().Get(package_id);
      } else {
        os << "Main";
      }
      continue;
    }
    const auto& name_scope = sem_ir().name_scopes().Get(name_scope_id);
    CARBON_KIND_SWITCH(sem_ir().insts().Get(name_scope.inst_id())) {
      case CARBON_KIND(SemIR::ImplDecl impl_decl): {
        const auto& impl = sem_ir().impls().Get(impl_decl.impl_id);

        auto facet_type = insts().GetAs<SemIR::FacetType>(
            constant_values().GetConstantInstId(impl.constraint_id));
        const auto& facet_type_info =
            sem_ir().facet_types().Get(facet_type.facet_type_id);
        auto interface_type = facet_type_info.TryAsSingleInterface();
        CARBON_CHECK(interface_type,
                     "Mangling of an impl of something other than a single "
                     "interface is not yet supported.");
        const auto& interface =
            sem_ir().interfaces().Get(interface_type->interface_id);
        names_to_render.push_back(
            {.name_scope_id = interface.scope_id, .prefix = ':'});

        auto self_inst =
            insts().Get(constant_values().GetConstantInstId(impl.self_id));
        CARBON_KIND_SWITCH(self_inst) {
          case CARBON_KIND(SemIR::ClassType class_type): {
            auto next_name_scope_id =
                sem_ir().classes().Get(class_type.class_id).scope_id;
            names_to_render.push_back(
                {.name_scope_id = next_name_scope_id, .prefix = '\0'});
            break;
          }
          case SemIR::AutoType::Kind:
          case SemIR::BoolType::Kind:
          case SemIR::BoundMethodType::Kind:
          case SemIR::IntLiteralType::Kind:
          case SemIR::LegacyFloatType::Kind:
          case SemIR::NamespaceType::Kind:
          case SemIR::SpecificFunctionType::Kind:
          case SemIR::StringType::Kind:
          case SemIR::TypeType::Kind:
          case SemIR::VtableType::Kind:
          case SemIR::WitnessType::Kind: {
            os << self_inst.kind().ir_name();
            break;
          }
          case CARBON_KIND(SemIR::IntType int_type): {
            os << (int_type.int_kind == SemIR::IntKind::Signed ? "i" : "u")
               << sem_ir().ints().Get(
                      sem_ir()
                          .insts()
                          .GetAs<SemIR::IntValue>(int_type.bit_width_id)
                          .int_id);
            break;
          }
          default:
            CARBON_FATAL("Attempting to mangle unsupported SemIR.");
            break;
        }
        // Skip the tail of the loop that adds the parent name scope to the
        // stack - the scope in which the impl was defined is not part of the
        // mangling, the constraint and interface alone uniquelify identify an
        // impl.
        continue;
      }
      case CARBON_KIND(SemIR::ClassDecl class_decl): {
        os << names().GetAsStringIfIdentifier(
            sem_ir().classes().Get(class_decl.class_id).name_id);
        break;
      }
      case CARBON_KIND(SemIR::InterfaceDecl interface_decl): {
        os << names().GetAsStringIfIdentifier(
            sem_ir().interfaces().Get(interface_decl.interface_id).name_id);
        break;
      }
      case SemIR::Namespace::Kind: {
        os << names().GetAsStringIfIdentifier(name_scope.name_id());
        break;
      }
      default:
        CARBON_FATAL("Attempting to mangle unsupported SemIR.");
        break;
    }
    if (!name_scope.is_imported_package()) {
      names_to_render.push_back(
          {.name_scope_id = name_scope.parent_scope_id(), .prefix = '.'});
    }
  }
}

auto Mangler::Mangle(SemIR::FunctionId function_id,
                     SemIR::SpecificId specific_id) -> std::string {
  const auto& function = sem_ir().functions().Get(function_id);
  if (SemIR::IsEntryPoint(sem_ir(), function_id)) {
    CARBON_CHECK(!specific_id.is_valid(), "entry point should not be generic");
    return "main";
  }
  std::string result;
  llvm::raw_string_ostream os(result);
  os << "_C";

  os << names().GetAsStringIfIdentifier(function.name_id);

  MangleInverseQualifiedNameScope(os, function.parent_scope_id);

  // TODO: Add proper support for generic entities. The ID we emit here will not
  // be consistent across object files.
  if (specific_id.is_valid()) {
    os << "." << specific_id.index;
  }

  return os.str();
}

}  // namespace Carbon::Lower
