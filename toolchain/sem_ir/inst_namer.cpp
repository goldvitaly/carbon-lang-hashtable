// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/sem_ir/inst_namer.h"

#include "common/ostream.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/base/shared_value_stores.h"
#include "toolchain/lex/tokenized_buffer.h"
#include "toolchain/parse/tree.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst_kind.h"
#include "toolchain/sem_ir/type_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::SemIR {

InstNamer::InstNamer(const File* sem_ir) : sem_ir_(sem_ir) {
  insts_.resize(sem_ir->insts().size(), {ScopeId::None, Namespace::Name()});
  labels_.resize(sem_ir->inst_blocks().size());
  scopes_.resize(static_cast<size_t>(GetScopeFor(NumberOfScopesTag())));
  generic_scopes_.resize(sem_ir->generics().size(), ScopeId::None);

  // Build the constants scope.
  CollectNamesInBlock(ScopeId::Constants, sem_ir->constants().array_ref());

  // Build the ImportRef scope.
  CollectNamesInBlock(ScopeId::ImportRefs, sem_ir->inst_blocks().Get(
                                               SemIR::InstBlockId::ImportRefs));

  // Build the file scope.
  CollectNamesInBlock(ScopeId::File, sem_ir->top_inst_block_id());

  // Build each function scope.
  for (auto [i, fn] : llvm::enumerate(sem_ir->functions().array_ref())) {
    FunctionId fn_id(i);
    auto fn_scope = GetScopeFor(fn_id);
    // TODO: Provide a location for the function for use as a
    // disambiguator.
    auto fn_loc = Parse::NodeId::Invalid;
    GetScopeInfo(fn_scope).name = globals_.AllocateName(
        *this, fn_loc, sem_ir->names().GetIRBaseName(fn.name_id).str());
    CollectNamesInBlock(fn_scope, fn.implicit_param_patterns_id);
    CollectNamesInBlock(fn_scope, fn.param_patterns_id);
    if (!fn.body_block_ids.empty()) {
      AddBlockLabel(fn_scope, fn.body_block_ids.front(), "entry", fn_loc);
    }
    for (auto block_id : fn.body_block_ids) {
      CollectNamesInBlock(fn_scope, block_id);
    }
    for (auto block_id : fn.body_block_ids) {
      AddBlockLabel(fn_scope, block_id);
    }
    CollectNamesInGeneric(fn_scope, fn.generic_id);
  }

  // Build each class scope.
  for (auto [i, class_info] : llvm::enumerate(sem_ir->classes().array_ref())) {
    ClassId class_id(i);
    auto class_scope = GetScopeFor(class_id);
    // TODO: Provide a location for the class for use as a disambiguator.
    auto class_loc = Parse::NodeId::Invalid;
    GetScopeInfo(class_scope).name = globals_.AllocateName(
        *this, class_loc,
        sem_ir->names().GetIRBaseName(class_info.name_id).str());
    AddBlockLabel(class_scope, class_info.body_block_id, "class", class_loc);
    CollectNamesInBlock(class_scope, class_info.body_block_id);
    CollectNamesInGeneric(class_scope, class_info.generic_id);
  }

  // Build each interface scope.
  for (auto [i, interface_info] :
       llvm::enumerate(sem_ir->interfaces().array_ref())) {
    InterfaceId interface_id(i);
    auto interface_scope = GetScopeFor(interface_id);
    // TODO: Provide a location for the interface for use as a disambiguator.
    auto interface_loc = Parse::NodeId::Invalid;
    GetScopeInfo(interface_scope).name = globals_.AllocateName(
        *this, interface_loc,
        sem_ir->names().GetIRBaseName(interface_info.name_id).str());
    AddBlockLabel(interface_scope, interface_info.body_block_id, "interface",
                  interface_loc);
    CollectNamesInBlock(interface_scope, interface_info.body_block_id);
    CollectNamesInGeneric(interface_scope, interface_info.generic_id);
  }

  // Build each impl scope.
  for (auto [i, impl_info] : llvm::enumerate(sem_ir->impls().array_ref())) {
    ImplId impl_id(i);
    auto impl_scope = GetScopeFor(impl_id);
    // TODO: Provide a location for the impl for use as a disambiguator.
    auto impl_loc = Parse::NodeId::Invalid;
    // TODO: Invent a name based on the self and constraint types.
    GetScopeInfo(impl_scope).name =
        globals_.AllocateName(*this, impl_loc, "impl");
    AddBlockLabel(impl_scope, impl_info.body_block_id, "impl", impl_loc);
    CollectNamesInBlock(impl_scope, impl_info.body_block_id);
    CollectNamesInGeneric(impl_scope, impl_info.generic_id);
  }
}

auto InstNamer::GetScopeName(ScopeId scope) const -> std::string {
  switch (scope) {
    case ScopeId::None:
      return "<invalid scope>";

    // These are treated as SemIR keywords.
    case ScopeId::File:
      return "file";
    case ScopeId::ImportRefs:
      return "imports";
    case ScopeId::Constants:
      return "constants";

    // For everything else, use an @ prefix.
    default:
      return ("@" + GetScopeInfo(scope).name.str()).str();
  }
}

auto InstNamer::GetUnscopedNameFor(InstId inst_id) const -> llvm::StringRef {
  if (!inst_id.is_valid()) {
    return "";
  }
  const auto& inst_name = insts_[inst_id.index].second;
  return inst_name ? inst_name.str() : "";
}

auto InstNamer::GetNameFor(ScopeId scope_id, InstId inst_id) const
    -> std::string {
  if (!inst_id.is_valid()) {
    return "invalid";
  }

  // Check for a builtin.
  if (SemIR::IsSingletonInstId(inst_id)) {
    return sem_ir_->insts().Get(inst_id).kind().ir_name().str();
  }

  if (inst_id == SemIR::Namespace::PackageInstId) {
    return "package";
  }

  const auto& [inst_scope, inst_name] = insts_[inst_id.index];
  if (!inst_name) {
    // This should not happen in valid IR.
    std::string str;
    llvm::raw_string_ostream str_stream(str);
    str_stream << "<unexpected>." << inst_id;
    auto loc_id = sem_ir_->insts().GetLocId(inst_id);
    // TODO: Consider handling inst_id cases.
    if (loc_id.is_node_id()) {
      const auto& tree = sem_ir_->parse_tree();
      auto token = tree.node_token(loc_id.node_id());
      str_stream << ".loc" << tree.tokens().GetLineNumber(token) << "_"
                 << tree.tokens().GetColumnNumber(token);
    }
    return str;
  }
  if (inst_scope == scope_id) {
    return ("%" + inst_name.str()).str();
  }
  return (GetScopeName(inst_scope) + ".%" + inst_name.str()).str();
}

auto InstNamer::GetUnscopedLabelFor(InstBlockId block_id) const
    -> llvm::StringRef {
  if (!block_id.is_valid()) {
    return "";
  }
  const auto& label_name = labels_[block_id.index].second;
  return label_name ? label_name.str() : "";
}

// Returns the IR name to use for a label, when referenced from a given scope.
auto InstNamer::GetLabelFor(ScopeId scope_id, InstBlockId block_id) const
    -> std::string {
  if (!block_id.is_valid()) {
    return "!invalid";
  }

  const auto& [label_scope, label_name] = labels_[block_id.index];
  if (!label_name) {
    // This should not happen in valid IR.
    std::string str;
    llvm::raw_string_ostream(str)
        << "<unexpected instblockref " << block_id << ">";
    return str;
  }
  if (label_scope == scope_id) {
    return ("!" + label_name.str()).str();
  }
  return (GetScopeName(label_scope) + ".!" + label_name.str()).str();
}

auto InstNamer::Namespace::Name::str() const -> llvm::StringRef {
  llvm::StringMapEntry<NameResult>* value = value_;
  CARBON_CHECK(value, "cannot print a null name");
  while (value->second.ambiguous && value->second.fallback) {
    value = value->second.fallback.value_;
  }
  return value->first();
}

auto InstNamer::Namespace::AllocateName(const InstNamer& inst_namer,
                                        SemIR::LocId loc_id, std::string name)
    -> Name {
  // The best (shortest) name for this instruction so far, and the current
  // name for it.
  Name best;
  Name current;

  // Add `name` as a name for this entity.
  auto add_name = [&](bool mark_ambiguous = true) {
    auto [it, added] = allocated.insert({name, NameResult()});
    Name new_name = Name(it);

    if (!added) {
      if (mark_ambiguous) {
        // This name was allocated for a different instruction. Mark it as
        // ambiguous and keep looking for a name for this instruction.
        new_name.SetAmbiguous();
      }
    } else {
      if (!best) {
        best = new_name;
      } else {
        CARBON_CHECK(current);
        current.SetFallback(new_name);
      }
      current = new_name;
    }
    return added;
  };

  // Use the given name if it's available.
  if (!name.empty()) {
    add_name();
  }

  // Append location information to try to disambiguate.
  // TODO: Consider handling inst_id cases.
  if (loc_id.is_node_id()) {
    const auto& tree = inst_namer.sem_ir_->parse_tree();
    auto token = tree.node_token(loc_id.node_id());
    llvm::raw_string_ostream(name)
        << ".loc" << tree.tokens().GetLineNumber(token);
    add_name();

    llvm::raw_string_ostream(name)
        << "_" << tree.tokens().GetColumnNumber(token);
    add_name();
  }

  // Append numbers until we find an available name.
  name += ".";
  auto name_size_without_counter = name.size();
  for (int counter = 1;; ++counter) {
    name.resize(name_size_without_counter);
    llvm::raw_string_ostream(name) << counter;
    if (add_name(/*mark_ambiguous=*/false)) {
      return best;
    }
  }
}

auto InstNamer::AddBlockLabel(ScopeId scope_id, InstBlockId block_id,
                              std::string name, SemIR::LocId loc_id) -> void {
  if (!block_id.is_valid() || labels_[block_id.index].second) {
    return;
  }

  if (!loc_id.is_valid()) {
    if (const auto& block = sem_ir_->inst_blocks().Get(block_id);
        !block.empty()) {
      loc_id = sem_ir_->insts().GetLocId(block.front());
    }
  }

  labels_[block_id.index] = {
      scope_id, GetScopeInfo(scope_id).labels.AllocateName(*this, loc_id,
                                                           std::move(name))};
}

// Finds and adds a suitable block label for the given SemIR instruction that
// represents some kind of branch.
auto InstNamer::AddBlockLabel(ScopeId scope_id, SemIR::LocId loc_id,
                              AnyBranch branch) -> void {
  llvm::StringRef name;
  switch (sem_ir_->parse_tree().node_kind(loc_id.node_id())) {
    case Parse::NodeKind::IfExprIf:
      switch (branch.kind) {
        case BranchIf::Kind:
          name = "if.expr.then";
          break;
        case Branch::Kind:
          name = "if.expr.else";
          break;
        case BranchWithArg::Kind:
          name = "if.expr.result";
          break;
        default:
          break;
      }
      break;

    case Parse::NodeKind::IfCondition:
      switch (branch.kind) {
        case BranchIf::Kind:
          name = "if.then";
          break;
        case Branch::Kind:
          name = "if.else";
          break;
        default:
          break;
      }
      break;

    case Parse::NodeKind::IfStatement:
      name = "if.done";
      break;

    case Parse::NodeKind::ShortCircuitOperandAnd:
      name = branch.kind == BranchIf::Kind ? "and.rhs" : "and.result";
      break;
    case Parse::NodeKind::ShortCircuitOperandOr:
      name = branch.kind == BranchIf::Kind ? "or.rhs" : "or.result";
      break;

    case Parse::NodeKind::WhileConditionStart:
      name = "while.cond";
      break;

    case Parse::NodeKind::WhileCondition:
      switch (branch.kind) {
        case BranchIf::Kind:
          name = "while.body";
          break;
        case Branch::Kind:
          name = "while.done";
          break;
        default:
          break;
      }
      break;

    default:
      break;
  }

  AddBlockLabel(scope_id, branch.target_id, name.str(), loc_id);
}

auto InstNamer::CollectNamesInBlock(ScopeId scope_id, InstBlockId block_id)
    -> void {
  if (block_id.is_valid()) {
    CollectNamesInBlock(scope_id, sem_ir_->inst_blocks().Get(block_id));
  }
}

auto InstNamer::CollectNamesInBlock(ScopeId top_scope_id,
                                    llvm::ArrayRef<InstId> block) -> void {
  llvm::SmallVector<std::pair<ScopeId, InstId>> insts;

  // Adds a scope and instructions to walk. Avoids recursion while allowing
  // the loop to below add more instructions during iteration. The new
  // instructions are queued such that they will be the next to be walked.
  // Internally that means they are reversed and added to the end of the vector,
  // since we pop from the back of the vector.
  auto queue_block_insts = [&](ScopeId scope_id,
                               llvm::ArrayRef<InstId> inst_ids) {
    for (auto inst_id : llvm::reverse(inst_ids)) {
      if (inst_id.is_valid()) {
        insts.push_back(std::make_pair(scope_id, inst_id));
      }
    }
  };
  auto queue_block_id = [&](ScopeId scope_id, InstBlockId block_id) {
    if (block_id.is_valid()) {
      queue_block_insts(scope_id, sem_ir_->inst_blocks().Get(block_id));
    }
  };

  queue_block_insts(top_scope_id, block);

  // Use bound names where available. Otherwise, assign a backup name.
  while (!insts.empty()) {
    auto [scope_id, inst_id] = insts.pop_back_val();

    Scope& scope = GetScopeInfo(scope_id);

    auto untyped_inst = sem_ir_->insts().Get(inst_id);
    auto add_inst_name = [&](std::string name) {
      ScopeId old_scope_id = insts_[inst_id.index].first;
      if (old_scope_id == ScopeId::None) {
        insts_[inst_id.index] = {
            scope_id, scope.insts.AllocateName(
                          *this, sem_ir_->insts().GetLocId(inst_id), name)};
      } else {
        CARBON_CHECK(old_scope_id == scope_id,
                     "Attempting to name inst in multiple scopes");
      }
    };
    auto add_inst_name_id = [&](NameId name_id, llvm::StringRef suffix = "") {
      add_inst_name(
          (sem_ir_->names().GetIRBaseName(name_id).str() + suffix).str());
    };
    auto add_int_or_float_type_name = [&](char type_literal_prefix,
                                          SemIR::InstId bit_width_id,
                                          llvm::StringRef suffix = "") {
      std::string name;
      llvm::raw_string_ostream out(name);
      out << type_literal_prefix;
      if (auto bit_width = sem_ir_->insts().TryGetAs<IntValue>(bit_width_id)) {
        out << sem_ir_->ints().Get(bit_width->int_id);
      } else {
        out << "N";
      }
      out << suffix;
      add_inst_name(std::move(name));
    };
    auto facet_access_name_id = [&](InstId facet_value_inst_id) -> NameId {
      if (auto name = sem_ir_->insts().TryGetAs<NameRef>(facet_value_inst_id)) {
        return name->name_id;
      } else if (auto symbolic = sem_ir_->insts().TryGetAs<BindSymbolicName>(
                     facet_value_inst_id)) {
        return sem_ir_->entity_names().Get(symbolic->entity_name_id).name_id;
      }
      return NameId::Invalid;
    };

    if (auto branch = untyped_inst.TryAs<AnyBranch>()) {
      AddBlockLabel(scope_id, sem_ir_->insts().GetLocId(inst_id), *branch);
    }

    CARBON_KIND_SWITCH(untyped_inst) {
      case AddrOf::Kind: {
        add_inst_name("addr");
        continue;
      }
      case ArrayType::Kind: {
        // TODO: Can we figure out the name of the type this is an array of?
        add_inst_name("array_type");
        continue;
      }
      case CARBON_KIND(AssociatedConstantDecl inst): {
        add_inst_name_id(inst.name_id);
        continue;
      }
      case CARBON_KIND(AssociatedEntity inst): {
        std::string name;
        llvm::raw_string_ostream out(name);
        out << "assoc" << inst.index.index;
        add_inst_name(std::move(name));
        continue;
      }
      case CARBON_KIND(AssociatedEntityType inst): {
        // TODO: Try to get the name of the interface associated with
        // `inst.interface_type_id`.
        if (auto fn_ty =
                sem_ir_->types().TryGetAs<FunctionType>(inst.entity_type_id)) {
          add_inst_name_id(sem_ir_->functions().Get(fn_ty->function_id).name_id,
                           ".assoc_type");
        } else {
          // TODO: Handle other cases.
          add_inst_name("assoc_type");
        }
        continue;
      }
      case BindAlias::Kind:
      case BindName::Kind:
      case BindSymbolicName::Kind:
      case ExportDecl::Kind: {
        auto inst = untyped_inst.As<AnyBindNameOrExportDecl>();
        add_inst_name_id(
            sem_ir_->entity_names().Get(inst.entity_name_id).name_id);
        continue;
      }
      case BindingPattern::Kind:
      case SymbolicBindingPattern::Kind: {
        auto inst = untyped_inst.As<AnyBindingPattern>();
        add_inst_name_id(
            sem_ir_->entity_names().Get(inst.entity_name_id).name_id, ".patt");
        continue;
      }
      case CARBON_KIND(BoolLiteral inst): {
        if (inst.value.ToBool()) {
          add_inst_name("true");
        } else {
          add_inst_name("false");
        }
        continue;
      }
      case CARBON_KIND(BoundMethod inst): {
        auto type_id = sem_ir_->insts().Get(inst.function_id).type_id();
        if (auto fn_ty = sem_ir_->types().TryGetAs<FunctionType>(type_id)) {
          add_inst_name_id(sem_ir_->functions().Get(fn_ty->function_id).name_id,
                           ".bound");
        } else {
          add_inst_name("bound_method");
        }
        continue;
      }
      case CARBON_KIND(Call inst): {
        auto callee_function =
            SemIR::GetCalleeFunction(*sem_ir_, inst.callee_id);
        if (!callee_function.function_id.is_valid()) {
          break;
        }
        const auto& function =
            sem_ir_->functions().Get(callee_function.function_id);
        // Name the call's result based on the callee.
        if (function.builtin_function_kind !=
            SemIR::BuiltinFunctionKind::None) {
          // For a builtin, use the builtin name. Otherwise, we'd typically pick
          // the name `Op` below, which is probably not very useful.
          add_inst_name(function.builtin_function_kind.name().str());
          continue;
        }

        add_inst_name_id(function.name_id, ".call");
        continue;
      }
      case CARBON_KIND(ClassDecl inst): {
        const auto& class_info = sem_ir_->classes().Get(inst.class_id);
        add_inst_name_id(class_info.name_id, ".decl");
        auto class_scope_id = GetScopeFor(inst.class_id);
        queue_block_id(class_scope_id, class_info.pattern_block_id);
        queue_block_id(class_scope_id, inst.decl_block_id);
        continue;
      }
      case CARBON_KIND(ClassType inst): {
        if (auto literal_info = NumericTypeLiteralInfo::ForType(*sem_ir_, inst);
            literal_info.is_valid()) {
          add_inst_name(literal_info.GetLiteralAsString(*sem_ir_));
          break;
        }
        add_inst_name_id(sem_ir_->classes().Get(inst.class_id).name_id);
        continue;
      }
      case CompleteTypeWitness::Kind: {
        // TODO: Can we figure out the name of the type this is a witness for?
        add_inst_name("complete_type");
        continue;
      }
      case ConstType::Kind: {
        // TODO: Can we figure out the name of the type argument?
        add_inst_name("const");
        continue;
      }
      case CARBON_KIND(FacetAccessType inst): {
        auto name_id = facet_access_name_id(inst.facet_value_inst_id);
        if (name_id.is_valid()) {
          add_inst_name_id(name_id, ".as_type");
        } else {
          add_inst_name("as_type");
        }
        continue;
      }
      case CARBON_KIND(FacetAccessWitness inst): {
        auto name_id = facet_access_name_id(inst.facet_value_inst_id);
        if (name_id.is_valid()) {
          add_inst_name_id(name_id, ".as_wit");
        } else {
          add_inst_name("as_wit");
        }
        continue;
      }
      case CARBON_KIND(FacetType inst): {
        const auto& facet_type_info =
            sem_ir_->facet_types().Get(inst.facet_type_id);
        bool has_where = facet_type_info.other_requirements ||
                         !facet_type_info.rewrite_constraints.empty();
        if (auto interface = facet_type_info.TryAsSingleInterface()) {
          const auto& interface_info =
              sem_ir_->interfaces().Get(interface->interface_id);
          add_inst_name_id(interface_info.name_id,
                           has_where ? "_where.type" : ".type");
        } else if (facet_type_info.impls_constraints.empty()) {
          add_inst_name(has_where ? "type_where" : "type");
        } else {
          add_inst_name("facet_type");
        }
        continue;
      }
      case CARBON_KIND(FacetValue inst): {
        if (auto facet_type =
                sem_ir_->types().TryGetAs<FacetType>(inst.type_id)) {
          const auto& facet_type_info =
              sem_ir_->facet_types().Get(facet_type->facet_type_id);
          if (auto interface = facet_type_info.TryAsSingleInterface()) {
            const auto& interface_info =
                sem_ir_->interfaces().Get(interface->interface_id);
            add_inst_name_id(interface_info.name_id, ".facet");
            continue;
          }
        }
        add_inst_name("facet_value");
        continue;
      }
      case FloatLiteral::Kind: {
        add_inst_name("float");
        continue;
      }
      case CARBON_KIND(FloatType inst): {
        add_int_or_float_type_name('f', inst.bit_width_id);
        continue;
      }
      case CARBON_KIND(FunctionDecl inst): {
        const auto& function_info = sem_ir_->functions().Get(inst.function_id);
        add_inst_name_id(function_info.name_id, ".decl");
        auto function_scope_id = GetScopeFor(inst.function_id);
        queue_block_id(function_scope_id, function_info.pattern_block_id);
        queue_block_id(function_scope_id, inst.decl_block_id);
        continue;
      }
      case CARBON_KIND(FunctionType inst): {
        add_inst_name_id(sem_ir_->functions().Get(inst.function_id).name_id,
                         ".type");
        continue;
      }
      case CARBON_KIND(GenericClassType inst): {
        add_inst_name_id(sem_ir_->classes().Get(inst.class_id).name_id,
                         ".type");
        continue;
      }
      case CARBON_KIND(GenericInterfaceType inst): {
        add_inst_name_id(sem_ir_->interfaces().Get(inst.interface_id).name_id,
                         ".type");
        continue;
      }
      case CARBON_KIND(ImplDecl inst): {
        auto impl_scope_id = GetScopeFor(inst.impl_id);
        queue_block_id(impl_scope_id,
                       sem_ir_->impls().Get(inst.impl_id).pattern_block_id);
        queue_block_id(impl_scope_id, inst.decl_block_id);
        break;
      }
      case ImplWitness::Kind: {
        // TODO: Include name of interface (is this available from the
        // specific?).
        add_inst_name("impl_witness");
        continue;
      }
      case CARBON_KIND(ImplWitnessAccess inst): {
        // TODO: Include information about the impl?
        std::string name;
        llvm::raw_string_ostream out(name);
        out << "impl.elem" << inst.index.index;
        add_inst_name(std::move(name));
        continue;
      }
      case CARBON_KIND(ImportDecl inst): {
        if (inst.package_id.is_valid()) {
          add_inst_name_id(inst.package_id, ".import");
        } else {
          add_inst_name("default.import");
        }
        continue;
      }
      case ImportRefUnloaded::Kind:
      case ImportRefLoaded::Kind: {
        add_inst_name("import_ref");
        // When building import refs, we frequently add instructions without
        // a block. Constants that refer to them need to be separately
        // named.
        auto const_id = sem_ir_->constant_values().Get(inst_id);
        if (const_id.is_valid() && const_id.is_template()) {
          auto const_inst_id = sem_ir_->constant_values().GetInstId(const_id);
          if (!insts_[const_inst_id.index].second) {
            queue_block_insts(ScopeId::ImportRefs,
                              llvm::ArrayRef(const_inst_id));
          }
        }
        continue;
      }
      case CARBON_KIND(InterfaceDecl inst): {
        const auto& interface_info =
            sem_ir_->interfaces().Get(inst.interface_id);
        add_inst_name_id(interface_info.name_id, ".decl");
        auto interface_scope_id = GetScopeFor(inst.interface_id);
        queue_block_id(interface_scope_id, interface_info.pattern_block_id);
        queue_block_id(interface_scope_id, inst.decl_block_id);
        continue;
      }
      case CARBON_KIND(IntType inst): {
        add_int_or_float_type_name(inst.int_kind == IntKind::Signed ? 'i' : 'u',
                                   inst.bit_width_id, ".builtin");
        continue;
      }
      case CARBON_KIND(IntValue inst): {
        std::string name;
        llvm::raw_string_ostream out(name);
        out << "int_" << sem_ir_->ints().Get(inst.int_id);
        add_inst_name(std::move(name));
        continue;
      }
      case CARBON_KIND(NameRef inst): {
        add_inst_name_id(inst.name_id, ".ref");
        continue;
      }
      // The namespace is specified here due to the name conflict.
      case CARBON_KIND(SemIR::Namespace inst): {
        add_inst_name_id(
            sem_ir_->name_scopes().Get(inst.name_scope_id).name_id());
        continue;
      }
      case OutParam::Kind:
      case ValueParam::Kind: {
        add_inst_name_id(untyped_inst.As<AnyParam>().pretty_name_id, ".param");
        continue;
      }
      case OutParamPattern::Kind:
      case ValueParamPattern::Kind: {
        add_inst_name_id(
            SemIR::Function::GetNameFromPatternId(*sem_ir_, inst_id),
            ".param_patt");
        continue;
      }
      case PointerType::Kind: {
        add_inst_name("ptr");
        continue;
      }
      case RequireCompleteType::Kind: {
        add_inst_name("require_complete");
        continue;
      }
      case ReturnSlotPattern::Kind: {
        add_inst_name_id(NameId::ReturnSlot, ".patt");
        continue;
      }
      case CARBON_KIND(SpecificFunction inst): {
        InstId callee_id = inst.callee_id;
        if (auto method = sem_ir_->insts().TryGetAs<BoundMethod>(callee_id)) {
          callee_id = method->function_id;
        }
        auto type_id = sem_ir_->insts().Get(callee_id).type_id();
        if (auto fn_ty = sem_ir_->types().TryGetAs<FunctionType>(type_id)) {
          add_inst_name_id(sem_ir_->functions().Get(fn_ty->function_id).name_id,
                           ".specific_fn");
        } else {
          add_inst_name("specific_fn");
        }
        continue;
      }
      case ReturnSlot::Kind: {
        add_inst_name_id(NameId::ReturnSlot);
        break;
      }
      case CARBON_KIND(SpliceBlock inst): {
        queue_block_id(scope_id, inst.block_id);
        break;
      }
      case StringLiteral::Kind: {
        add_inst_name("str");
        continue;
      }
      case CARBON_KIND(StructValue inst): {
        if (auto fn_ty =
                sem_ir_->types().TryGetAs<FunctionType>(inst.type_id)) {
          add_inst_name_id(
              sem_ir_->functions().Get(fn_ty->function_id).name_id);
        } else if (auto class_ty =
                       sem_ir_->types().TryGetAs<ClassType>(inst.type_id)) {
          add_inst_name_id(sem_ir_->classes().Get(class_ty->class_id).name_id,
                           ".val");
        } else if (auto generic_class_ty =
                       sem_ir_->types().TryGetAs<GenericClassType>(
                           inst.type_id)) {
          add_inst_name_id(
              sem_ir_->classes().Get(generic_class_ty->class_id).name_id,
              ".generic");
        } else if (auto generic_interface_ty =
                       sem_ir_->types().TryGetAs<GenericInterfaceType>(
                           inst.type_id)) {
          add_inst_name_id(sem_ir_->interfaces()
                               .Get(generic_interface_ty->interface_id)
                               .name_id,
                           ".generic");
        } else {
          if (sem_ir_->inst_blocks().Get(inst.elements_id).empty()) {
            add_inst_name("empty_struct");
          } else {
            add_inst_name("struct");
          }
        }
        continue;
      }
      case CARBON_KIND(StructType inst): {
        const auto& fields = sem_ir_->struct_type_fields().Get(inst.fields_id);
        if (fields.empty()) {
          add_inst_name("empty_struct_type");
          continue;
        }
        std::string name = "struct_type";
        for (auto field : fields) {
          name += ".";
          name += sem_ir_->names().GetIRBaseName(field.name_id).str();
        }
        add_inst_name(std::move(name));
        continue;
      }
      case CARBON_KIND(TupleAccess inst): {
        std::string name;
        llvm::raw_string_ostream out(name);
        out << "tuple.elem" << inst.index.index;
        add_inst_name(std::move(name));
        continue;
      }
      case CARBON_KIND(TupleType inst): {
        if (inst.elements_id == TypeBlockId::Empty) {
          add_inst_name("empty_tuple.type");
        } else {
          add_inst_name("tuple.type");
        }
        continue;
      }
      case CARBON_KIND(TupleValue inst): {
        if (sem_ir_->types().Is<ArrayType>(inst.type_id)) {
          add_inst_name("array");
        } else if (inst.elements_id == InstBlockId::Empty) {
          add_inst_name("empty_tuple");
        } else {
          add_inst_name("tuple");
        }
        continue;
      }
      case CARBON_KIND(UnboundElementType inst): {
        if (auto class_ty =
                sem_ir_->types().TryGetAs<ClassType>(inst.class_type_id)) {
          add_inst_name_id(sem_ir_->classes().Get(class_ty->class_id).name_id,
                           ".elem");
        } else {
          add_inst_name("elem_type");
        }
        continue;
      }
      case CARBON_KIND(VarStorage inst): {
        add_inst_name_id(inst.name_id, ".var");
        continue;
      }
      default: {
        break;
      }
    }

    // Sequentially number all remaining values.
    if (untyped_inst.kind().value_kind() != InstValueKind::None) {
      add_inst_name("");
    }
  }
}

auto InstNamer::CollectNamesInGeneric(ScopeId scope_id, GenericId generic_id)
    -> void {
  if (!generic_id.is_valid()) {
    return;
  }
  generic_scopes_[generic_id.index] = scope_id;
  const auto& generic = sem_ir_->generics().Get(generic_id);
  CollectNamesInBlock(scope_id, generic.decl_block_id);
  CollectNamesInBlock(scope_id, generic.definition_block_id);
}

}  // namespace Carbon::SemIR
