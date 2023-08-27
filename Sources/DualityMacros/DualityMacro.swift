import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func makeInitialCaps(_ str: String) -> String {
    let firstCharIndexStart = str.startIndex
    let firstCharIndexEnd = str.index(after: firstCharIndexStart)
    let firstCharIndexRange = firstCharIndexStart ..< firstCharIndexEnd
    return str.replacingCharacters(
        in: firstCharIndexRange,
        with: str[firstCharIndexRange].uppercased()
    )
}

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
                message: NonStaticMemberDiagnosticMessage.singleton,
                highlights: [Syntax(sourceFunction.modifiers)],
                fixIt: FixIt(
                    message: NonStaticMemberDiagnosticMessage.FixMessage.singleton,
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
        let initialCapsFunctionNameText = makeInitialCaps(sourceFunction.name.text)
        let dualFunctionName = TokenSyntax.identifier("co" + initialCapsFunctionNameText).with(\.leadingTrivia, " ")
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
    protocol sourceProtocol: ProtocolDeclSyntax,
    inContext context: some MacroExpansionContext,
    removingAttribute selfAttribute: AttributeSyntax
) -> ProtocolDeclSyntax? {
    guard sourceProtocol.inheritanceClause == nil else {
        context.diagnose(Diagnostic(
            node: sourceProtocol,
            message: ProtocolInheritanceDiagnosticMessage.singleton,
            highlights: [Syntax(sourceProtocol.inheritanceClause!)],
            fixIt: FixIt(
                message: ProtocolInheritanceDiagnosticMessage.FixMessage.singleton,
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceProtocol),
                        newNode: Syntax(sourceProtocol.with(\.inheritanceClause, nil))
                    )
                ]
            )
        ))
        return nil
    }
    guard sourceProtocol.primaryAssociatedTypeClause == nil else {
        context.diagnose(Diagnostic(
            node: sourceProtocol,
            message: PrimaryAssociatedTypesDiagnosticMessage.singleton,
            highlights: [Syntax(sourceProtocol.primaryAssociatedTypeClause!)],
            fixIt: FixIt(
                message: PrimaryAssociatedTypesDiagnosticMessage.FixMessage.singleton,
                changes: [
                    FixIt.Change.replace(
                        oldNode: Syntax(sourceProtocol),
                        newNode: Syntax(sourceProtocol.with(\.primaryAssociatedTypeClause, nil))
                    )
                ]
            )
        ))
        return nil
    }
    let attrs = sourceProtocol.attributes.filter {
        $0 == .attribute(selfAttribute)
    }
    let dualDeclName = TokenSyntax.identifier("Co" + sourceProtocol.name.text).with(\.leadingTrivia, " ")
    let dualDeclHeader: SyntaxNodeString =
        "\(attrs)\(sourceProtocol.modifiers)\(TokenSyntax.keyword(.protocol))\(dualDeclName)"
    return try! ProtocolDeclSyntax(dualDeclHeader) {
        for sourceMember in sourceProtocol.memberBlock.members {
            if let dualMember = dualize(member: sourceMember, inContext: context) {
                dualMember
            }
        }
    }
}

public struct TrivialMacro: PeerMacro {
    @inlinable
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) -> [DeclSyntax] {
        []
    }
}

public struct DualizeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        guard let sourceProtocol = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: declaration,
                message: NotAProtocolDiagnosticMessage.singleton
            ))
            return []
        }
        guard let dualProtocol = dualize(
            protocol: sourceProtocol,
            inContext: context,
            removingAttribute: node
        ) else {
            return []
        }
        return [DeclSyntax(dualProtocol.formatted().cast(ProtocolDeclSyntax.self))]
    }
}

@main
struct DualityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DualizeMacro.self
        // SelfDualMacro.self,
    ]
}
