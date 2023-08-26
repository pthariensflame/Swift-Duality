import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DualityMacroError: Error {
  case notAProtocol(declaration: DeclSyntax)
  case unsupportedFeature(explanation: String)
  case memberWithBody(member: MemberBlockItemSyntax)
}

private func dualizeFunctionSignature(_ sourceSignature: FunctionSignatureSyntax) throws
  -> FunctionSignatureSyntax
{
  guard sourceSignature.effectSpecifiers == nil else {
    throw DualityMacroError.unsupportedFeature(explanation: "Effect specifiers")
  }
  let sourceParams = sourceSignature.parameterClause.parameters
  let sourceResult = sourceSignature.returnClause?.type
  guard sourceParams.count <= 1 else {
    throw DualityMacroError.unsupportedFeature(explanation: "Multiargument functions")
  }
  let dualParams = FunctionParameterListSyntax {
    if let sRes = sourceResult {
      FunctionParameterSyntax(firstName: "_", type: sRes)
    }
  }
  let dualResult = sourceParams.first?.type
  return FunctionSignatureSyntax(
    parameterClause: FunctionParameterClauseSyntax(parameters: dualParams),
    returnClause: dualResult.map { ReturnClauseSyntax.init(type: $0) })
}

private func dualizeMember(_ sourceMember: MemberBlockItemSyntax) throws -> MemberBlockItemSyntax {
  if let sourceFunction = sourceMember.decl.as(FunctionDeclSyntax.self) {
    if sourceFunction.body == nil {
      if sourceFunction.modifiers.contains(where: { $0.name == "static" }) {
        let dualSignature = try dualizeFunctionSignature(sourceFunction.signature)
        let dualFunctionSyntax: SyntaxNodeString =
          """
          \(sourceFunction.attributes) \(sourceFunction.modifiers)
          func \(raw: "co" + sourceFunction.name.text)\(dualSignature)
          """
        return MemberBlockItemSyntax(try FunctionDeclSyntax(dualFunctionSyntax))!
      } else {
        throw DualityMacroError.unsupportedFeature(explanation: "Instance methods")
      }
    } else {
      throw DualityMacroError.memberWithBody(member: sourceMember)
    }
  } else {
    throw DualityMacroError.unsupportedFeature(
      explanation: "Unsupported protocol member kind")
  }
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
    let dualDeclHeader: SyntaxNodeString =
      """
      \(sourceDecl.attributes) \(sourceDecl.modifiers)
      protocol \(raw: "Co" + sourceDecl.name.text)
      """
    let dualDecl = try ProtocolDeclSyntax(dualDeclHeader) {
      for sourceMember in sourceDecl.memberBlock.members {
        try dualizeMember(sourceMember)
      }
    }
    return [DeclSyntax(dualDecl)]
  }
}

@main
struct DualityPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DualizeMacro.self
    //    SelfDualMacro.self,
  ]
}
