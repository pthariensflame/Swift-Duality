import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
    let dualReturns = if sourceParamsNoVariadics.count == 1 {
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
            message: EffectSpecifiersDiagnosticMessage(),
            highlights: [Syntax(sourceSignature.effectSpecifiers!)],
            fixIt: FixIt(
                message: EffectSpecifiersDiagnosticMessage.FixMessage(),
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceSignature),
                        newNode: Syntax(sourceSignature.with(\.effectSpecifiers, nil))
                    )
                ]
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

func dualize(
    function sourceFunction: FunctionDeclSyntax,
    as dualName: TokenSyntax,
    inContext context: some MacroExpansionContext,
    removingAttributes attrsToRemove: [AttributeSyntax]
) -> FunctionDeclSyntax? {
    let sourceAttrs = sourceFunction.attributes.filter { sourceAttr in
        !attrsToRemove.contains { attrToRemove in
            sourceAttr.as(AttributeSyntax.self) == attrToRemove
        }
    }
    let mutatingKeyword = sourceFunction.modifiers.first {
        $0.name.tokenKind == .keyword(.mutating)
    }
    guard mutatingKeyword == nil else {
        context.diagnose(Diagnostic(
            node: sourceFunction,
            message: MutatingMemberDiagnosticMessage(),
            highlights: [Syntax(mutatingKeyword!)],
            fixIt: FixIt(
                message: MutatingMemberDiagnosticMessage.FixMessage(),
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceFunction),
                        newNode: Syntax(sourceFunction.with(
                            \.modifiers,
                            sourceFunction.modifiers.filter {
                                $0.name.tokenKind != .keyword(.mutating)
                            }
                        ))
                    )
                ]
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
        var paramsWithSelf = [FunctionParameterSyntax(firstName: "_", type: IdentifierTypeSyntax(name: "Self"))]
        paramsWithSelf.append(contentsOf: sourceFunction.signature.parameterClause.parameters)
        context.diagnose(Diagnostic(
            node: sourceFunction,
            message: NonStaticMemberDiagnosticMessage(),
            highlights: [Syntax(sourceFunction.modifiers)],
            fixIt: FixIt(
                message: NonStaticMemberDiagnosticMessage.FixMessage(),
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceFunction),
                        newNode: Syntax(sourceFunction.with(
                            \.modifiers,
                            DeclModifierListSyntax(modifiersWithStatic)
                        ))
                    ),
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceFunction),
                        newNode: Syntax(sourceFunction.with(
                            \.signature.parameterClause.parameters,
                            FunctionParameterListSyntax(paramsWithSelf)
                        ))
                    )
                ]
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
    let dualFunctionHeader: SyntaxNodeString =
        "\(sourceAttrs)\(sourceFunction.modifiers)\(TokenSyntax.keyword(.func))\(dualName)\(dualSignature)"
    return try! FunctionDeclSyntax(dualFunctionHeader)
}
