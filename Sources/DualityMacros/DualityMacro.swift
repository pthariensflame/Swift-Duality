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
                changes: [FixIt.Change.replace(
                    oldNode: Syntax(sourceProtocol),
                    newNode: Syntax(sourceProtocol.with(\.inheritanceClause, nil))
                )]
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
                changes: [FixIt.Change.replace(
                    oldNode: Syntax(sourceProtocol),
                    newNode: Syntax(sourceProtocol.with(\.primaryAssociatedTypeClause, nil))
                )]
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
