@attached(peer, names: prefixed(Co), arbitrary)
public macro Dualize<T>(dualName: String? = nil) = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

// @attached(extension, names: prefixed(co))
// public macro SelfDual<T>() = #externalMacro(module: "DualityMacros", type: "SelfDualMacro")

@attached(peer)
public macro Coinit<T>(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Covar<T>(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Cosubscript<T>(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro Coinstance<T>(_: Bool = true) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")

@attached(peer)
public macro DualName<T>(_: String? = nil) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
