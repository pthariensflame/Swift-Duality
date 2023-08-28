@attached(peer, names: prefixed(Co))
public macro Dualize() = #externalMacro(module: "DualityMacros", type: "DualizeMacro")
@attached(peer, names: arbitrary)
public macro Dualize(dualName: String) = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

// @attached(extension, names: arbitrary)
// public macro SelfDual() = #externalMacro(module: "DualityMacros", type: "SelfDualMacro")

@attached(peer)
public macro DualName(_: String) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Coinit() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Covar() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Cosubscript() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
@attached(peer)
public macro Coinstance() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
