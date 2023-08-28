import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DualityMacros)
import DualityMacros
#endif

final class DualityStaticFuncTests: XCTestCase {
    func testDualizeEmpty() throws {
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
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }

    func testDualizeRenamed() throws {
#if canImport(DualityMacros)
        assertMacroExpansion(
            """
            @Dualize(dualName: "Two")
            protocol One {
                @DualName("two")
                static func one()
            }
            """,
            expandedSource:
            """
            protocol One {
                static func one()
            }

            protocol Two {
                static func two() -> ()
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

    func testDualizePointed() throws {
#if canImport(DualityMacros)
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
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }

    func testDualizeMonoid() throws {
#if canImport(DualityMacros)
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
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }

    func testDualizeTape() throws {
#if canImport(DualityMacros)
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
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }

    func testDualizeRing() throws {
#if canImport(DualityMacros)
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
#else
        throw XCTSkip(
            "macros are only supported when running tests for the host platform"
        )
#endif
    }

    func testDualizeAssorted() throws {
#if canImport(DualityMacros)
        assertMacroExpansion(
            """
            @Dualize
            protocol Assorted {
                static func doSomething(_: Self, withContext: [Self])
                static func doItAll(_: Self...)
                static func aDifferentThing(something: Self)
            }
            """,
            expandedSource:
            """
            protocol Assorted {
                static func doSomething(_: Self, withContext: [Self])
                static func doItAll(_: Self...)
                static func aDifferentThing(something: Self)
            }

            protocol CoAssorted {
                static func coDoSomething() -> (Self, withContext: [Self])
                static func coDoItAll() -> [Self]
                static func coADifferentThing() -> Self
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
    
    func testDualizeRingAlt() throws {
#if canImport(DualityMacros)
        assertMacroExpansion(
            """
            @Dualize
            protocol RingAlt {
                @DualName("toBool")
                static func fromBool(_: Bool) -> Self
                static func combine(mode: Bool, _: Self, _: Self) -> Self
                @DualName("negate")
                static func negate(_: Self) -> Self
            }
            """,
            expandedSource:
            """
            protocol RingAlt {
                static func fromBool(_: Bool) -> Self
                static func combine(mode: Bool, _: Self, _: Self) -> Self
                static func negate(_: Self) -> Self
            }

            protocol CoRingAlt {
                static func toBool(_: Self) -> Bool
                static func coCombine(_: Self) -> (mode: Bool, Self, Self)
                static func negate(_: Self) -> Self
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
    
    func testDualizeRingOperators() throws {
#if canImport(DualityMacros)
        assertMacroExpansion(
            """
            @Dualize
            protocol Ring {
                static func zero() -> Self
                static func one() -> Self
                @DualName("coAdd")
                static func *(_: Self, _: Self) -> Self
                @DualName("coMultiply")
                static func +(_: Self, _: Self) -> Self
                @DualName("-")
                static func -(_: Self) -> Self
            }
            """,
            expandedSource:
            """
            protocol Ring {
                static func zero() -> Self
                static func one() -> Self
                static func *(_: Self, _: Self) -> Self
                static func +(_: Self, _: Self) -> Self
                static func -(_: Self) -> Self
            }

            protocol CoRing {
                static func coZero(_: Self) -> ()
                static func coOne(_: Self) -> ()
                static func coAdd(_: Self) -> (Self, Self)
                static func coMultiply(_: Self) -> (Self, Self)
                static func - (_: Self) -> Self
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
