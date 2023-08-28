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
        let (dualNameRaw, dualNameSyntax): (String?, StringLiteralExprSyntax?)
        if let dualNameAttr = sourceFunction.attributes.first(where: {
            if let attr = $0.as(AttributeSyntax.self),
               let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                return attrName.name.text == "DualName"
            } else {
                return false
            }
        }).map({ $0.cast(AttributeSyntax.self) }) {
            guard
                dualNameAttr
                .arguments!
                .cast(LabeledExprListSyntax.self)
                .first!
                .expression
                .is(StringLiteralExprSyntax.self)
            else {
                context.diagnose(Diagnostic(
                    node: dualNameAttr,
                    message: GivenNameNotLiteralDiagnosticMessage(),
                    highlights: [Syntax(dualNameAttr.arguments!)]
                ))
                return nil
            }
            let dualNameSyn = dualNameAttr
                .arguments!
                .cast(LabeledExprListSyntax.self)
                .first!
                .expression
                .cast(StringLiteralExprSyntax.self)
            (dualNameRaw, dualNameSyntax) = (dualNameSyn.representedLiteralValue, dualNameSyn)
        } else {
            (dualNameRaw, dualNameSyntax) = (nil, nil)
        }
        let dualNameUnvalidated = TokenSyntax.identifier(dualNameRaw ?? "co" + makeInitialCaps(sourceFunction.name.text))
        guard let dualName = try? TokenSyntax(validating: dualNameUnvalidated.with(\.leadingTrivia, " ")) else {
            context.diagnose(Diagnostic(
                node: dualNameSyntax.map(Syntax.init) ?? Syntax(sourceFunction.name),
                message: InvalidIdentifierDiagnosticMessage(ident: dualNameUnvalidated)
            ))
            return nil
        }
        guard let dualFunction = dualize(
            function: sourceFunction,
            as: dualName,
            inContext: context
        ) else {
            return nil
        }
        return MemberBlockItemSyntax(decl: dualFunction)
    } else {
        context.diagnose(Diagnostic(
            node: sourceMember,
            message: UnsupportedMemberKindDiagnosticMessage()
        ))
        return nil
    }
}
