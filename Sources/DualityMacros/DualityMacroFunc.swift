import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func dualize(
    member sourceMember: MemberBlockItemSyntax,
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
        guard !withSelf else {
            // TODO: implement withSelf handling
            var modifiersWithStatic = [DeclModifierSyntax(name: "static")]
            modifiersWithStatic.append(contentsOf: sourceFunction.modifiers)
            context.diagnose(Diagnostic(
                node: sourceFunction,
                message: NonStaticMemberDiagnosticMessage.singleton,
                highlights: [Syntax(sourceFunction.modifiers)],
                fixIt: FixIt(
                    message: NonStaticMemberDiagnosticMessage.FixMessage.singleton,
                    changes: [FixIt.Change.replace(
                        oldNode: Syntax(sourceFunction),
                        newNode: Syntax(sourceFunction.with(\.modifiers, DeclModifierListSyntax(modifiersWithStatic)))
                    )]
                )
            ))
            return nil
        }
        guard let dualSignature = dualize(
            functionSignature: sourceFunction.signature,
            withSelf: withSelf,
            inContext: context
        ) else {
            return nil
        }
        let dualFunctionName = TokenSyntax.identifier("co" + sourceFunction.name.text).with(\.leadingTrivia, " ")
        let dualFunctionHeader: SyntaxNodeString =
            "\(sourceFunction.attributes)\(sourceFunction.modifiers)\(TokenSyntax.keyword(.func))\(dualFunctionName)\(dualSignature)"
        let dualFunction = try! FunctionDeclSyntax(dualFunctionHeader)
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
    returnValue sourceReturns: ReturnClauseSyntax?,
    withSelf: Bool,
    inContext context: some MacroExpansionContext
) -> (
    dualParams: FunctionParameterClauseSyntax,
    dualReturns: ReturnClauseSyntax?
)? {
    assert(!withSelf) // TODO: implement withSelf handing
    let sourceReturnsType = sourceReturns?.type ?? TypeSyntax(TupleTypeSyntax(elements: []))
    var dualParamsMap: [(TokenSyntax, TypeSyntax)] = []
    if let sourceReturnsTuple = sourceReturnsType.as(TupleTypeSyntax.self) {
        for sourceReturnElem in sourceReturnsTuple.elements {
            let dualParamLabel = sourceReturnElem.firstName ?? "_"
            dualParamsMap.append((dualParamLabel, sourceReturnElem.type))
        }
    } else {
        dualParamsMap.append(("_", sourceReturnsType))
    }
    let dualParams = FunctionParameterClauseSyntax {
        for (dualParamLabel, dualParamType) in dualParamsMap {
            FunctionParameterSyntax(firstName: dualParamLabel, type: dualParamType)
        }
    }
    let sourceParamsNoVariadics = sourceParams.parameters.map { sourceParam in
        let dualReturnType = if sourceParam.ellipsis == nil {
            sourceParam.type
        } else {
            TypeSyntax(ArrayTypeSyntax(element: sourceParam.type))
        }
        return sourceParam.with(\.ellipsis, nil).with(\.type, dualReturnType)
    }
    let dualReturns = if
        sourceParamsNoVariadics.count == 1,
        sourceParamsNoVariadics.first!.firstName.text == "_",
        sourceParamsNoVariadics.first!.secondName == nil ||
        sourceParamsNoVariadics.first!.secondName?.text == "_"
    {
        ReturnClauseSyntax(type: sourceParamsNoVariadics.first!.type)
    } else {
        ReturnClauseSyntax(type: TupleTypeSyntax(elements: TupleTypeElementListSyntax {
            for sourceParam in sourceParamsNoVariadics {
                let (dualReturnLabel, colon): (TokenSyntax?, TokenSyntax?) = if sourceParam.firstName.text == "_" {
                    (nil, nil)
                } else {
                    (sourceParam.firstName, .colonToken())
                }
                TupleTypeElementSyntax(firstName: dualReturnLabel, colon: colon, type: sourceParam.type)
            }
        }))
    }
    return (dualParams, dualReturns)
}

func dualize(
    functionSignature sourceSignature: FunctionSignatureSyntax,
    withSelf: Bool,
    inContext context: some MacroExpansionContext
) -> FunctionSignatureSyntax? {
    assert(!withSelf) // TODO: implement withSelf handing
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
    guard let (dualParams, dualReturns) = dualize(
        parameterList: sourceSignature.parameterClause,
        returnValue: sourceSignature.returnClause,
        withSelf: withSelf,
        inContext: context
    ) else {
        return nil
    }
    return FunctionSignatureSyntax(parameterClause: dualParams, returnClause: dualReturns)
}
