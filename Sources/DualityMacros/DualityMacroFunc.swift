import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func dualize(
    member sourceMember: MemberBlockItemSyntax,
    byWrapping existingMember: DeclReferenceExprSyntax? = nil,
    inContext context: some MacroExpansionContext
) -> MemberBlockItemSyntax? {
    if let sourceFunction = sourceMember.decl.as(FunctionDeclSyntax.self) {
        let mutatingKeyword = sourceFunction.modifiers.first {
            $0.name.tokenKind == .keyword(.mutating)
        }
        guard mutatingKeyword == nil else {
            context.diagnose(Diagnostic(
                node: sourceFunction,
                message: MutatingMemberDiagnosticMessage.singleton,
                highlights: [Syntax(mutatingKeyword!)],
                fixIt: FixIt(
                    message: MutatingMemberDiagnosticMessage.FixMessage.singleton,
                    changes: [FixIt.Change.replace(
                        oldNode: Syntax(sourceFunction),
                        newNode: Syntax(sourceFunction.with(\.modifiers, sourceFunction.modifiers.filter {
                            $0.name.tokenKind != .keyword(.mutating)
                        }))
                    )]
                )
            ))
            return nil
        }
        let withSelf = !sourceFunction.modifiers.contains {
            $0.name.tokenKind == .keyword(.static)
        }
        guard let dualSignature = dualize(
            functionSignature: sourceFunction.signature,
            withSelf: withSelf,
            inContext: context
        ) else {
            return nil
        }
        let dualFunctionHeader: SyntaxNodeString =
            """
            \(sourceFunction.attributes)
            \(sourceFunction.modifiers) func \(raw: "co" + sourceFunction.name.text)\(dualSignature)
            """
        let dualFunction = if let existingMember {
            try! FunctionDeclSyntax(dualFunctionHeader) {
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
            try! FunctionDeclSyntax(dualFunctionHeader)
        }
        return MemberBlockItemSyntax(decl: dualFunction)
    } else {
        context.diagnose(Diagnostic(
            node: sourceMember,
            message: UnsupportedMemberKindDiagnosticMessage.singleton
        ))
        return nil
    }
}

func dualize(
    parameterList sourceParams: FunctionParameterClauseSyntax,
    withSelf: Bool,
    inContext context: some MacroExpansionContext
) -> ReturnClauseSyntax? {
    fatalError() // TODO:
}

func dualize(
    returnValue sourceReturns: ReturnClauseSyntax?,
    withSelf: Bool,
    inContext context: some MacroExpansionContext
) -> FunctionParameterClauseSyntax {
    fatalError() // TODO:
}

func dualize(
    functionSignature sourceSignature: FunctionSignatureSyntax,
    withSelf: Bool,
    inContext context: some MacroExpansionContext
) -> FunctionSignatureSyntax? {
    guard sourceSignature.effectSpecifiers == nil else {
        context.diagnose(Diagnostic(
            node: sourceSignature,
            message: EffectSpecifiersDiagnosticMessage.singleton,
            highlights: [Syntax(sourceSignature.effectSpecifiers!)],
            fixIt: FixIt(
                message: EffectSpecifiersDiagnosticMessage.FixMessage.singleton,
                changes: [FixIt.Change.replace(
                    oldNode: Syntax(sourceSignature),
                    newNode: Syntax(sourceSignature.with(\.effectSpecifiers, nil))
                )]
            )
        ))
        return nil
    }
    return FunctionSignatureSyntax(
        parameterClause: dualize(
            returnValue: sourceSignature.returnClause,
            withSelf: withSelf,
            inContext: context
        ),
        returnClause: dualize(
            parameterList: sourceSignature.parameterClause,
            withSelf: withSelf,
            inContext: context
        )
    )
}
