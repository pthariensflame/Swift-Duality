import SwiftDiagnostics
import SwiftSyntax

public struct GivenNameNotLiteralDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "The dual name given should be a string literal"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "GivenNameNotLiteral")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}

public struct InvalidIdentifierDiagnosticMessage: DiagnosticMessage {
    public let ident: TokenSyntax
    
    public var message: String {
        "The string \"\(ident)\" is invalid as an identifier"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "NotAProtocol")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}

public struct NotAProtocolDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Dualization can only be applied to protocols"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "NotAProtocol")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}

public struct ProtocolInheritanceDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Protocols with inheritance clauses are not yet supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "ProtocolInheritance")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
    
    public struct FixMessage: FixItMessage {
        public var message: String {
            "Remove the inheritence clause"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "ProtocolInheritanceFix")
        }
    }
}

public struct PrimaryAssociatedTypesDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Protocols with primary associated types are not yet supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "PrimaryAssociatedTypes")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
    
    public struct FixMessage: FixItMessage {
        public var message: String {
            "Remove the primary associated types"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "PrimaryAssociatedTypesFix")
        }
    }
}

public struct MutatingMemberDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Mutating protocol members are not yet supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "MutatingMember")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
    
    public struct FixMessage: FixItMessage {
        public var message: String {
            "Remove the mutating modifier"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "MutatingMemberFix")
        }
    }
}

public struct EffectSpecifiersDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Protocol members with effect specifiers are not yet supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "EffectSpecifiers")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
    
    public struct FixMessage: FixItMessage {
        public var message: String {
            "Remove the effect specifiers"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "EffectSpecifiersFix")
        }
    }
}

public struct NonStaticMemberDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Protocol members that are not static are not supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "NonStaticMember")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
    
    public struct FixMessage: FixItMessage {
        public var message: String {
            "Add the static modifier and add an initial Self parameter"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "NonStaticMemberFix")
        }
    }
}

public struct TypeAliasDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "Protocol members that are type aliases are not supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "TypeAlias")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}

public struct UnsupportedMemberKindDiagnosticMessage: DiagnosticMessage {
    public var message: String {
        "This kind of protocol member is not yet supported"
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "DualityMacros", id: "UnsupportedMemberKind")
    }
    
    public var severity: DiagnosticSeverity {
        .error
    }
}
