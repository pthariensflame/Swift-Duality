import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DualityMacros)
  import DualityMacros

  let testMacros: [String: Macro.Type] = [
    "Dualize": DualizeMacro.self,
//    "SelfDual": SelfDualMacro.self,
  ]
#endif

final class DualityTests: XCTestCase {
  func testDualizeMacro() throws {
    #if canImport(DualityMacros)
//      assertMacroExpansion(
//        """
//        #stringify(a + b)
//        """,
//        expandedSource: """
//          (a + b, "a + b")
//          """,
//        macros: testMacros
//      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
