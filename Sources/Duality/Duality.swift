@attached(peer, names: prefixed(Co))
public macro Dualize<T>() = #externalMacro(module: "DualityMacros", type: "DualizeMacro")

//@attached(extension, names: prefixed(co))
//public macro SelfDual<T>() = #externalMacro(module: "DualityMacros", type: "SelfDualMacro")
