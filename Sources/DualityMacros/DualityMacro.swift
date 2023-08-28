import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func dualize(
    protocol sourceProtocol: ProtocolDeclSyntax,
    as dualName: TokenSyntax,
    inContext context: some MacroExpansionContext,
    removingAttribute selfAttribute: AttributeSyntax
) -> ProtocolDeclSyntax? {
    guard sourceProtocol.inheritanceClause == nil else {
        context.diagnose(Diagnostic(
            node: sourceProtocol,
            message: ProtocolInheritanceDiagnosticMessage(),
            highlights: [Syntax(sourceProtocol.inheritanceClause!)],
            fixIt: FixIt(
                message: ProtocolInheritanceDiagnosticMessage.FixMessage(),
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
            message: PrimaryAssociatedTypesDiagnosticMessage(),
            highlights: [Syntax(sourceProtocol.primaryAssociatedTypeClause!)],
            fixIt: FixIt(
                message: PrimaryAssociatedTypesDiagnosticMessage.FixMessage(),
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
    let dualDeclHeader: SyntaxNodeString =
        "\(attrs)\(sourceProtocol.modifiers)\(TokenSyntax.keyword(.protocol))\(dualName)"
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
                message: NotAProtocolDiagnosticMessage()
            ))
            return []
        }
        let dualNameSyntax = node.arguments?
            .cast(LabeledExprListSyntax.self)
            .first?
            .expression
            .as(StringLiteralExprSyntax.self)
        let dualNameRaw = dualNameSyntax?.representedLiteralValue
        let dualNameUnvalidated = TokenSyntax.identifier(dualNameRaw ?? "Co" + sourceProtocol.name.text)
        guard let dualName = try? TokenSyntax(validating: dualNameUnvalidated.with(\.leadingTrivia, " ")) else {
            context.diagnose(Diagnostic(
                node: dualNameSyntax.map(Syntax.init) ?? Syntax(sourceProtocol.name),
                message: InvalidIdentifierDiagnosticMessage(ident: dualNameUnvalidated)
            ))
            return []
        }
        guard let dualProtocol = dualize(
            protocol: sourceProtocol,
            as: dualName,
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
    var providingMacros: [Macro.Type] { [
        DualizeMacro.self,
        // SelfDualMacro.self,
        TrivialMacro.self
    ] }
}
