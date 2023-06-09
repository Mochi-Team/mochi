//
//  Function.swift
//
//
//  Created by ErrorErrorError on 4/7/23.
//
//

import Foundation

// MARK: - WasmInstance.Function

// swiftlint:disable line_length
public extension WasmInstance {
    struct Function {
        public typealias ImportHandler = (UnsafeMutablePointer<UInt64>?, UnsafeMutableRawPointer?) -> UnsafeRawPointer?

        let name: String
        let handler: ImportHandler
        let signature: String

        init(
            name: String,
            signature: String,
            handler: @escaping Function.ImportHandler
        ) {
            self.name = name
            self.signature = signature
            self.handler = handler
        }
    }
}

public extension WasmInstance.Function {
    init(
        _ name: String,
        _ block: @escaping () throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate()
        ) { _, _ in
            do {
                try block()
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<R: WasmValue>(
        _ name: String,
        _ block: @escaping () throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(ret: R.wasmType)
        ) { stack, _ in
            do {
                let ret = try block()
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue>(
        _ name: String,
        _ block: @escaping (A) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                try block(arg1)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, ret: R.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let ret = try block(arg1)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                try block(arg1, arg2)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let ret = try block(arg1, arg2)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                try block(arg1, arg2, arg3)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let ret = try block(arg1, arg2, arg3)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                try block(arg1, arg2, arg3, arg4)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let ret = try block(arg1, arg2, arg3, arg4)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                try block(arg1, arg2, arg3, arg4, arg5)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let ret = try block(arg1, arg2, arg3, arg4, arg5)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                try block(arg1, arg2, arg3, arg4, arg5, arg6)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType)
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, K: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                let arg11: K = try NativeFunction.argument(from: stack, at: 10)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, K: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let arg11: K = try NativeFunction.argument(from: stack, at: 11)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, K: WasmValue, L: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                let arg11: K = try NativeFunction.argument(from: stack, at: 10)
                let arg12: L = try NativeFunction.argument(from: stack, at: 11)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, K: WasmValue, L: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let arg11: K = try NativeFunction.argument(from: stack, at: 11)
                let arg12: L = try NativeFunction.argument(from: stack, at: 12)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<A: WasmValue, B: WasmValue, C: WasmValue, D: WasmValue, E: WasmValue, F: WasmValue, G: WasmValue, H: WasmValue, I: WasmValue, J: WasmValue, K: WasmValue, L: WasmValue, M: WasmValue>(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                let arg11: K = try NativeFunction.argument(from: stack, at: 10)
                let arg12: L = try NativeFunction.argument(from: stack, at: 11)
                let arg13: M = try NativeFunction.argument(from: stack, at: 12)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<
        A: WasmValue,
        B: WasmValue,
        C: WasmValue,
        D: WasmValue,
        E: WasmValue,
        F: WasmValue,
        G: WasmValue,
        H: WasmValue,
        I: WasmValue,
        J: WasmValue,
        K: WasmValue,
        L: WasmValue,
        M: WasmValue,
        R: WasmValue
    >(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let arg11: K = try NativeFunction.argument(from: stack, at: 11)
                let arg12: L = try NativeFunction.argument(from: stack, at: 12)
                let arg13: M = try NativeFunction.argument(from: stack, at: 13)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<
        A: WasmValue,
        B: WasmValue,
        C: WasmValue,
        D: WasmValue,
        E: WasmValue,
        F: WasmValue,
        G: WasmValue,
        H: WasmValue,
        I: WasmValue,
        J: WasmValue,
        K: WasmValue,
        L: WasmValue,
        M: WasmValue,
        N: WasmValue
    >(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M, N) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType, N.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                let arg11: K = try NativeFunction.argument(from: stack, at: 10)
                let arg12: L = try NativeFunction.argument(from: stack, at: 11)
                let arg13: M = try NativeFunction.argument(from: stack, at: 12)
                let arg14: N = try NativeFunction.argument(from: stack, at: 13)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<
        A: WasmValue,
        B: WasmValue,
        C: WasmValue,
        D: WasmValue,
        E: WasmValue,
        F: WasmValue,
        G: WasmValue,
        H: WasmValue,
        I: WasmValue,
        J: WasmValue,
        K: WasmValue,
        L: WasmValue,
        M: WasmValue,
        N: WasmValue,
        R: WasmValue
    >(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M, N) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType, N.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let arg11: K = try NativeFunction.argument(from: stack, at: 11)
                let arg12: L = try NativeFunction.argument(from: stack, at: 12)
                let arg13: M = try NativeFunction.argument(from: stack, at: 13)
                let arg14: N = try NativeFunction.argument(from: stack, at: 14)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<
        A: WasmValue,
        B: WasmValue,
        C: WasmValue,
        D: WasmValue,
        E: WasmValue,
        F: WasmValue,
        G: WasmValue,
        H: WasmValue,
        I: WasmValue,
        J: WasmValue,
        K: WasmValue,
        L: WasmValue,
        M: WasmValue,
        N: WasmValue,
        O: WasmValue
    >(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType, N.wasmType, O.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 0)
                let arg2: B = try NativeFunction.argument(from: stack, at: 1)
                let arg3: C = try NativeFunction.argument(from: stack, at: 2)
                let arg4: D = try NativeFunction.argument(from: stack, at: 3)
                let arg5: E = try NativeFunction.argument(from: stack, at: 4)
                let arg6: F = try NativeFunction.argument(from: stack, at: 5)
                let arg7: G = try NativeFunction.argument(from: stack, at: 6)
                let arg8: H = try NativeFunction.argument(from: stack, at: 7)
                let arg9: I = try NativeFunction.argument(from: stack, at: 8)
                let arg10: J = try NativeFunction.argument(from: stack, at: 9)
                let arg11: K = try NativeFunction.argument(from: stack, at: 10)
                let arg12: L = try NativeFunction.argument(from: stack, at: 11)
                let arg13: M = try NativeFunction.argument(from: stack, at: 12)
                let arg14: N = try NativeFunction.argument(from: stack, at: 13)
                let arg15: O = try NativeFunction.argument(from: stack, at: 13)
                try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<
        A: WasmValue,
        B: WasmValue,
        C: WasmValue,
        D: WasmValue,
        E: WasmValue,
        F: WasmValue,
        G: WasmValue,
        H: WasmValue,
        I: WasmValue,
        J: WasmValue,
        K: WasmValue,
        L: WasmValue,
        M: WasmValue,
        N: WasmValue,
        O: WasmValue,
        R: WasmValue
    >(
        _ name: String,
        _ block: @escaping (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.generate(
                args: A.wasmType, B.wasmType, C.wasmType, D.wasmType, E.wasmType, F.wasmType, G.wasmType, H.wasmType, I.wasmType, J.wasmType, K.wasmType, L.wasmType, M.wasmType, N.wasmType,
                O.wasmType,
                ret: R.wasmType
            )
        ) { stack, _ in
            do {
                let arg1: A = try NativeFunction.argument(from: stack, at: 1)
                let arg2: B = try NativeFunction.argument(from: stack, at: 2)
                let arg3: C = try NativeFunction.argument(from: stack, at: 3)
                let arg4: D = try NativeFunction.argument(from: stack, at: 4)
                let arg5: E = try NativeFunction.argument(from: stack, at: 5)
                let arg6: F = try NativeFunction.argument(from: stack, at: 6)
                let arg7: G = try NativeFunction.argument(from: stack, at: 7)
                let arg8: H = try NativeFunction.argument(from: stack, at: 8)
                let arg9: I = try NativeFunction.argument(from: stack, at: 9)
                let arg10: J = try NativeFunction.argument(from: stack, at: 10)
                let arg11: K = try NativeFunction.argument(from: stack, at: 11)
                let arg12: L = try NativeFunction.argument(from: stack, at: 12)
                let arg13: M = try NativeFunction.argument(from: stack, at: 13)
                let arg14: N = try NativeFunction.argument(from: stack, at: 14)
                let arg15: O = try NativeFunction.argument(from: stack, at: 15)
                let ret = try block(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
                try NativeFunction.pushReturnValue(ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }
}

let importedFunctionInternalError = UnsafeRawPointer(UnsafeMutableRawPointer.allocate(
    byteCount: _importedFunctionInternalError.count, alignment: MemoryLayout<CChar>.alignment
))
private let _importedFunctionInternalError = "ImportedFunctionInternalError".utf8CString
