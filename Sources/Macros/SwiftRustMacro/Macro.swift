import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct MacroPlugin: CompilerPlugin {
    var providingMacros: [SwiftSyntaxMacros.Macro.Type] = []
}
