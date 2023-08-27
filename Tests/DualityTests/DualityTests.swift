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

        assertMacroExpansion(
            """
            @Dualize
            protocol Tape {
                static func split() -> (left: Self, Int, right: Self)
            }
            """,
            expandedSource:
            """
            protocol Tape {
                static func split() -> (left: Self, Int, right: Self)
            }

            protocol CoTape {
                static func cosplit(left: Self, _: Int, right: Self) -> ()
            }
            """,
            macros: testMacros
        )

        assertMacroExpansion(
            """
            @Dualize
            protocol Ring {
                static func zero() -> Self
                static func one() -> Self
                static func add(_: Self, _: Self) -> Self
                static func multiply(_: Self, _: Self) -> Self
                static func negate(_: Self) -> Self
            }
            """,
            expandedSource:
            """
            protocol Ring {
                static func zero() -> Self
                static func one() -> Self
                static func add(_: Self, _: Self) -> Self
                static func multiply(_: Self, _: Self) -> Self
                static func negate(_: Self) -> Self
            }

            protocol CoRing {
                static func cozero(_: Self) -> ()
                static func coone(_: Self) -> ()
                static func coadd(_: Self) -> (Self, Self)
                static func comultiply(_: Self) -> (Self, Self)
                static func conegate(_: Self) -> Self
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
