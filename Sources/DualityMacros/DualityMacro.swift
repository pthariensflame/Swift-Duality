import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DualityMacroError: Error {
  case notAProtocol(declaration: DeclSyntax)
  case unsupportedFeature(explanation: String)
}

public struct DualizeMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let sourceDecl = declaration.as(ProtocolDeclSyntax.self) else {
      throw DualityMacroError.notAProtocol(declaration: DeclSyntax(declaration))
    }
    guard sourceDecl.inheritanceClause == nil else {
      throw DualityMacroError.unsupportedFeature(explanation: "Protocol inheritence")
    }
    guard sourceDecl.primaryAssociatedTypeClause == nil else {
      throw DualityMacroError.unsupportedFeature(explanation: "Primary associated types")
    }
    let dualDeclHeader: SyntaxNodeString = "\(sourceDecl.attributes) \(sourceDecl.modifiers) protocol Co\(raw: sourceDecl.name.text)"
    let dualDecl = try ProtocolDeclSyntax(dualDeclHeader) {
      for sourceMember in sourceDecl.memberBlock.members {
        if let sourceFunction = sourceMember.decl.as(FunctionDeclSyntax.self) {
          if (sourceFunction.modifiers.contains { $0.name == "static" }) {
            
          }
        } else {
          throw DualityMacroError.unsupportedFeature(explanation: "Unsupported protocol member kind")
        }
      }
    }
    return [DeclSyntax(dualDecl)]
  }
}

@main
struct DualityPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DualizeMacro.self,
//    SelfDualMacro.self,
  ]
}
