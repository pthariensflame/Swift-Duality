import SwiftDiagnostics

public struct NotAProtocolDiagnosticMessage: DiagnosticMessage {
    private init() {}
    
    public static let singleton: Self = .init()
    
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
    private init() {}
    
    public static let singleton: Self = .init()
    
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
        private init() {}
        
        public static let singleton: Self = .init()
        
        public var message: String {
            "Remove the inheritence clause"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "ProtocolInheritanceFix")
        }
    }
}

public struct PrimaryAssociatedTypesDiagnosticMessage: DiagnosticMessage {
    private init() {}
    
    public static let singleton: Self = .init()
    
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
        private init() {}
        
        public static let singleton: Self = .init()
        
        public var message: String {
            "Remove the primary associated types"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "PrimaryAssociatedTypesFix")
        }
    }
}

public struct MutatingMemberDiagnosticMessage: DiagnosticMessage {
    private init() {}
    
    public static let singleton: Self = .init()
    
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
        private init() {}
        
        public static let singleton: Self = .init()
        
        public var message: String {
            "Remove the mutating modifier"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "MutatingMemberFix")
        }
    }
}

public struct EffectSpecifiersDiagnosticMessage: DiagnosticMessage {
    private init() {}
    
    public static let singleton: Self = .init()
    
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
        private init() {}
        
        public static let singleton: Self = .init()
        
        public var message: String {
            "Remove the effect specifiers"
        }
        
        public var fixItID: MessageID {
            MessageID(domain: "DualityMacros", id: "EffectSpecifiersFix")
        }
    }
}

public struct UnsupportedMemberKindDiagnosticMessage: DiagnosticMessage {
    private init() {}
    
    public static let singleton: Self = .init()
    
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
