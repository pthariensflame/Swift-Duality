import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DualityMacros)
  import DualityMacros

  let testMacros: [String: Macro.Type] = [
    "Dualize": DualizeMacro.self
    //    "SelfDual": SelfDualMacro.self,
  ]
#endif

final class DualityTests: XCTestCase {
  func testDualizeMacro() throws {
    #if canImport(DualityMacros)
      assertMacroExpansion(
        """
        @Dualize
        protocol Monoid {
          static func empty() -> Self
          static func combine(_: (Self, Self)) -> Self
        }
        """,
        expandedSource:
          """
          protocol Monoid {
            static func empty() -> Self
            static func combine(_: (Self, Self)) -> Self
          }
          protocol CoMonoid {
            static func coempty(_: Self)
            static func cocombine(_: Self) -> (Self, Self)
          }
          """,
        macros: testMacros
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
