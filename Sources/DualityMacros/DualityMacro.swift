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
            \(sourceFunction.attributes)
            \(sourceFunction.modifiers) func \(raw: "co" + sourceFunction.name.text)\(dualSignature)
            """
        let dualFunction = if let existingMember {
            try FunctionDeclSyntax(dualFunctionHeader) {
                FunctionCallExprSyntax(callee: existingMember) {
                    for param in dualSignature.parameterClause.parameters {
                        LabeledExprSyntax(
                            label: param.firstName,
                            expression: DeclReferenceExprSyntax(baseName: param.secondName ?? param.firstName)
                        )
                    }
                }
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

private func dualize(parameterList sourceParams: FunctionParameterClauseSyntax) throws -> ReturnClauseSyntax? {
    fatalError() // TODO:
}

private func dualize(returnValue sourceReturns: ReturnClauseSyntax?) throws -> FunctionParameterClauseSyntax {
    fatalError() // TODO:
}

private func dualize(functionSignature sourceSignature: FunctionSignatureSyntax) throws
    -> FunctionSignatureSyntax
{
    guard sourceSignature.effectSpecifiers == nil else {
        throw DualityMacroError.unsupportedFeature(explanation: "Effect specifiers")
    }
    return try FunctionSignatureSyntax(
        parameterClause: dualize(returnValue: sourceSignature.returnClause),
        returnClause: dualize(parameterList: sourceSignature.parameterClause)
    )
}

private func dualize(protocol sourceProtocol: ProtocolDeclSyntax) throws -> ProtocolDeclSyntax {
    guard sourceProtocol.inheritanceClause == nil else {
        throw DualityMacroError.unsupportedFeature(explanation: "Protocol inheritence")
    }
    guard sourceProtocol.primaryAssociatedTypeClause == nil else {
        throw DualityMacroError.unsupportedFeature(explanation: "Primary associated types")
    }
    let dualDeclHeader: SyntaxNodeString =
        """
        \(sourceProtocol.attributes)
        \(sourceProtocol.modifiers) protocol \(raw: "Co" + sourceProtocol.name.text)
        """
    return try ProtocolDeclSyntax(dualDeclHeader) {
        for sourceMember in sourceProtocol.memberBlock.members {
            try dualize(member: sourceMember)
        }
    }
}

public struct DualizeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let sourceProtocol = declaration.as(ProtocolDeclSyntax.self) else {
            throw DualityMacroError.notAProtocol(declaration: DeclSyntax(declaration))
        }
        return try [DeclSyntax(dualize(protocol: sourceProtocol))]
    }
}

@main
struct DualityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DualizeMacro.self
        // SelfDualMacro.self,
    ]
}
