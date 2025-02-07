import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ToolPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ToolMacro.self
    ]
}
