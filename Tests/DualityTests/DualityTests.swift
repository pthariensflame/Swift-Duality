import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DualityMacros)
import DualityMacros

let testMacros: [String: Macro.Type] = [
    "Dualize": DualizeMacro.self
    // "SelfDual": SelfDualMacro.self,
]
#endif

final class DualityTests: XCTestCase {
    func testDualizeMacro() throws {
#if canImport(DualityMacros)
        assertMacroExpansion(
            """
            @Dualize
            protocol Empty {}
            """,
            expandedSource:
            """
            protocol Empty {}

            protocol CoEmpty {
            }
            """,
            macros: testMacros
        )

        assertMacroExpansion(
            """
            @Dualize
            protocol Pointed {
                static func point() -> Self
            }
            """,
            expandedSource:
            """
            protocol Pointed {
                static func point() -> Self
            }

            protocol CoPointed {
                static func copoint(_: Self) -> ()
            }
            """,
            macros: testMacros
        )

        assertMacroExpansion(
            """
            @Dualize
            protocol Monoid {
                static func empty() -> Self
                static func combine(left: Self, right: Self) -> Self
            }
            """,
            expandedSource:
            """
            protocol Monoid {
                static func empty() -> Self
                static func combine(left: Self, right: Self) -> Self
            }

            protocol CoMonoid {
                static func coempty(_: Self) -> ()
                static func cocombine(_: Self) -> (left: Self, right: Self)
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }
}
