@attached(peer, names: prefixed(Co))
public macro Dualize<T>() = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

// @attached(extension, names: prefixed(co))
// public macro SelfDual<T>() = #externalMacro(module: "DualityMacros", type: "SelfDualMacro")

@attached(peer)
public macro Coinit<T>() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Covar<T>() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Cosubscript<T>() = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
