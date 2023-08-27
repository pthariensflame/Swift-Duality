@attached(peer, names: prefixed(Co))
public macro Dualize<T>(_ name: String? = nil) = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

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
public macro DualName<T>(_ name: String? = nil) = #externalMacro(module: "DualityMacros", type: "TrivialMacro")
