import Foundation

extension WasmInterpreter {
    func call(
        _ name: String,
        _ args: [any WasmTypeProtocol] = []
    ) throws {
        try _call(
            function(named: name),
            args: args.map {
                try .init(wasmType: $0)
            }
        )
    }

    func call<R: WasmTypeProtocol>(
        _ name: String,
        _ args: [any WasmTypeProtocol] = []
    ) throws -> R {
        try _call(
            function(named: name),
            args: args.map {
                try .init(wasmType: $0)
            }
        )
    }
}
