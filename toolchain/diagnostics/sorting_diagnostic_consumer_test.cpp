// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/diagnostics/sorting_diagnostic_consumer.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "llvm/ADT/StringRef.h"
#include "toolchain/diagnostics/diagnostic_emitter.h"
#include "toolchain/diagnostics/mocks.h"

namespace Carbon {
namespace {

using ::Carbon::Testing::IsSingleDiagnostic;
using ::testing::InSequence;

CARBON_DIAGNOSTIC(TestDiagnostic, Error, "M{0}", int);

struct FakeDiagnosticConverter : DiagnosticConverter<DiagnosticLoc> {
  auto ConvertLoc(DiagnosticLoc loc, ContextFnT /*context_fn*/) const
      -> DiagnosticLoc override {
    return loc;
  }
};

TEST(SortedDiagnosticEmitterTest, SortErrors) {
  FakeDiagnosticConverter converter;
  Testing::MockDiagnosticConsumer consumer;
  SortingDiagnosticConsumer sorting_consumer(consumer);
  DiagnosticEmitter<DiagnosticLoc> emitter(converter, sorting_consumer);

  emitter.Emit({"f", "line", 2, 1}, TestDiagnostic, 1);
  emitter.Emit({"f", "line", 1, 1}, TestDiagnostic, 2);
  emitter.Emit({"f", "line", 1, 3}, TestDiagnostic, 3);
  emitter.Emit({"f", "line", 3, 4}, TestDiagnostic, 4);
  emitter.Emit({"f", "line", 3, 2}, TestDiagnostic, 5);
  emitter.Emit({"f", "line", 3, 2}, TestDiagnostic, 6);

  InSequence s;
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 1, 1, "M2")));
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 1, 3, "M3")));
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 2, 1, "M1")));
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 3, 2, "M5")));
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 3, 2, "M6")));
  EXPECT_CALL(consumer, HandleDiagnostic(IsSingleDiagnostic(
                            DiagnosticKind::TestDiagnostic,
                            DiagnosticLevel::Error, 3, 4, "M4")));
  sorting_consumer.Flush();
}

}  // namespace
}  // namespace Carbon
