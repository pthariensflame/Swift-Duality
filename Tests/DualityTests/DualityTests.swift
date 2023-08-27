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
                static func coPoint(_: Self) -> ()
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
                static func coEmpty(_: Self) -> ()
                static func coCombine(_: Self) -> (left: Self, right: Self)
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
                static func coSplit(left: Self, _: Int, right: Self) -> ()
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
                static func coZero(_: Self) -> ()
                static func coOne(_: Self) -> ()
                static func coAdd(_: Self) -> (Self, Self)
                static func coMultiply(_: Self) -> (Self, Self)
                static func coNegate(_: Self) -> Self
            }
            """,
            macros: testMacros
        )

        assertMacroExpansion(
            """
            @Dualize
            protocol WithContext {
                static func doSomething(_: Self, withContext: [Self])
                static func doItAll(_: Self...)
                static func aDifferentThing(something: Self)
            }
            """,
            expandedSource:
            """
            protocol WithContext {
                static func doSomething(_: Self, withContext: [Self])
                static func doItAll(_: Self...)
                static func aDifferentThing(something: Self)
            }

            protocol CoWithContext {
                static func coDoSomething() -> (Self, withContext: [Self])
                static func coDoItAll() -> [Self]
                static func coADifferentThing() -> (something: Self)
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
