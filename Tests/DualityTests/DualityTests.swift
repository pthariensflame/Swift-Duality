import SwiftSyntaxMacros
import XCTest

#if canImport(DualityMacros)
import DualityMacros

let testMacros: [String: Macro.Type] = [
    "Dualize": DualizeMacro.self,
    // "SelfDual": SelfDualMacro.self,
    "DualName": TrivialMacro.self,
    "Coinit": TrivialMacro.self,
    "Covar": TrivialMacro.self,
    "Cosubscript": TrivialMacro.self,
    "Coinstance": TrivialMacro.self
]
#endif
