@attached(peer, names: prefixed(Co))
public macro Dualize() = #externalMacro(module: "DualityMacros", type: "DualizeMacro")
@attached(peer, names: arbitrary)
public macro Dualize(dualName: String) = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

// @attached(extension, names: arbitrary)
// public macro SelfDual() = #externalMacro(module: "DualityMacros", type: "SelfDualMacro")

@attached(peer)
public macro DualName(_: String) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Coinit(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Covar(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Cosubscript(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Coinstance(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
