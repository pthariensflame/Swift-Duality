import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum DualityMacroError: Error {
    case notAProtocol(declaration: DeclSyntax)
    case unsupportedFeature(explanation: String)
    case memberWithBody(member: MemberBlockItemSyntax)
}

private func dualize(
    member sourceMember: MemberBlockItemSyntax,
    byWrapping existingMember: DeclReferenceExprSyntax? = nil
) throws -> MemberBlockItemSyntax {
    if let sourceFunction = sourceMember.decl.as(FunctionDeclSyntax.self) {
        guard sourceFunction.body == nil else {
            throw DualityMacroError.memberWithBody(member: sourceMember)
        }
        guard sourceFunction.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
        else {
            throw DualityMacroError.unsupportedFeature(explanation: "Instance methods")
        }
        guard !sourceFunction.modifiers.contains(where: { $0.name.tokenKind == .keyword(.mutating) })
        else {
            throw DualityMacroError.unsupportedFeature(explanation: "Mutating methods")
        }
        let dualSignature = try dualize(functionSignature: sourceFunction.signature)
        let dualFunctionHeader: SyntaxNodeString =
            """
            \(sourceFunction.attributes) \(sourceFunction.modifiers)
            func \(raw: "co" + sourceFunction.name.text)\(dualSignature)
            """
        let dualFunction = if let existingMember {
            try FunctionDeclSyntax(dualFunctionHeader) {
                FunctionCallExprSyntax(callee: existingMember) {}
            }
        } else {
            try FunctionDeclSyntax(dualFunctionHeader)
        }
        return MemberBlockItemSyntax(decl: dualFunction)
    } else {
        throw DualityMacroError.unsupportedFeature(
            explanation: "Unsupported protocol member kind")
    }
}

private func dualize(functionSignature sourceSignature: FunctionSignatureSyntax) throws
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
        returnClause: dualResult.map { ReturnClauseSyntax(type: $0) }
    )
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
                try dualize(member: sourceMember)
            }
        }
        return [DeclSyntax(dualDecl)]
    }
}

@main
struct DualityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DualizeMacro.self
        // SelfDualMacro.self,
    ]
}
