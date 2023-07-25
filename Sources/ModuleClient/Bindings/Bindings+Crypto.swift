//
//  HostModuleInterop+Crypto.swift
//
//
//  Created by ErrorErrorError on 6/7/23.
//
//

import CommonCrypto
import CryptoKit
import Foundation
import WasmInterpreter

// MARK: Crypto

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func cryptoImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "crypto") {
            WasmInstance.Function("crypto_get_data_len") { [self] (
                hostPtr: Int32
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    guard let data = alloc[hostPtr] as? Data else {
                        return 0
                    }
                    return .init(data.count)
                }
            }

            WasmInstance.Function("crypto_get_data") { [self] (
                hostPtr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard let data = alloc[hostPtr] as? Data else {
                        return
                    }

                    try? memory.write(
                        with: data.dropLast(data.count - Int(bufLen)),
                        byteOffset: .init(bufPtr)
                    )
                }
            }

            WasmInstance.Function("crypto_base64_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let value = try memory.string(
                        byteOffset: .init(valuePtr),
                        length: .init(valueLen)
                    )

                    return alloc.add(Data(base64Encoded: value) ?? .init())
                }
            }

            WasmInstance.Function("crypto_base64_string") { [self] (
                bytesPtr: Int32,
                bytesLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let value = try memory.data(
                        byteOffset: .init(bytesPtr),
                        length: .init(bytesLen)
                    )

                    return alloc.add(value.base64EncodedString())
                }
            }

            WasmInstance.Function("crypto_utf8_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let value = try memory.string(
                        byteOffset: .init(valuePtr),
                        length: .init(valueLen)
                    )

                    return alloc.add(value.data(using: .utf8) ?? .init())
                }
            }

            WasmInstance.Function("crypto_pbkdf2") { [self] (
                hashFunction: Int32,
                passwordPtr: Int32,
                passwordLen: Int32,
                saltPtr: Int32,
                saltLen: Int32,
                rounds: Int32,
                keyCount: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let password = try memory.string(byteOffset: .init(passwordPtr), length: .init(passwordLen))
                    let salt = try memory.data(byteOffset: .init(saltPtr), length: .init(saltLen))

                    var derivedKeyData = Data(repeating: 0, count: .init(keyCount))
                    let derivedCount = derivedKeyData.count

                    let status = derivedKeyData.withUnsafeMutableBytes { derivedKeyDataPtr in
                        salt.withUnsafeBytes { saltPtr in
                            CCKeyDerivationPBKDF(
                                CCPBKDFAlgorithm(kCCPBKDF2),
                                password,
                                password.count,
                                saltPtr.baseAddress,
                                salt.count,
                                CCPBKDFAlgorithm(hashFunction),
                                .init(rounds),
                                derivedKeyDataPtr.baseAddress,
                                derivedCount
                            )
                        }
                    }

                    if status != kCCSuccess {
                        Swift.print("Failed to generate pbkdf2, status: \(status)")
                    }

                    return alloc.add(derivedKeyData)
                }
            }

            WasmInstance.Function("crypto_md5_hash") { [self] (
                inputPtr: Int32,
                inputLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let data = try memory.data(byteOffset: .init(inputPtr), length: .init(inputLen))
                    var function = Insecure.MD5()
                    function.update(data: data)
                    return alloc.add(Data(function.finalize()))
                }
            }

            WasmInstance.Function("crypto_generate_random_bytes") { [self] (
                count: Int32
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    var bytes = Data(count: .init(count))
                    bytes.withUnsafeMutableBytes { pointer in
                        guard let address = pointer.baseAddress else {
                            return
                        }
                        _ = SecRandomCopyBytes(kSecRandomDefault, .init(count), address)
                    }
                    return alloc.add(bytes)
                }
            }

            WasmInstance.Function("crypto_aes_encrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let message = try memory.data(
                        byteOffset: .init(msgPtr),
                        length: .init(msgLen)
                    )

                    let key = try memory.data(
                        byteOffset: .init(keyPtr),
                        length: .init(keyLen)
                    )

                    let iv = try memory.data(
                        byteOffset: .init(ivPtr),
                        length: .init(ivLen)
                    )

                    var keySize = kCCKeySizeAES128

                    if key.count == kCCKeySizeAES128 {
                        keySize = kCCKeySizeAES128
                    } else if key.count == kCCKeySizeAES192 {
                        keySize = kCCKeySizeAES192
                    } else if key.count == kCCKeySizeAES256 {
                        keySize = kCCKeySizeAES256
                    } else {
                        keySize = key.count
                    }

                    guard iv.count == kCCBlockSizeAES128 else {
                        throw ModuleClient.Error.unknown(msg: "block size not equal to aes128: \(iv.count)")
                    }

                    var outLength = 0
                    var outBytes = [UInt8](repeating: 0, count: message.count + kCCBlockSizeAES128)

                    _ = message.withUnsafeBytes { msgPtr in
                        key.withUnsafeBytes { keyPtr in
                            iv.withUnsafeBytes { ivPtr in
                                CCCrypt(
                                    CCOperation(kCCEncrypt),
                                    CCAlgorithm(kCCAlgorithmAES),
                                    CCOptions(kCCOptionPKCS7Padding),
                                    keyPtr.baseAddress,
                                    keySize,
                                    ivPtr.baseAddress,
                                    msgPtr.baseAddress,
                                    msgPtr.count,
                                    &outBytes,
                                    outBytes.count,
                                    &outLength
                                )
                            }
                        }
                    }
                    return alloc.add(Data(bytes: outBytes, count: outLength))
                }
            }

            WasmInstance.Function("crypto_aes_decrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let encryptedMessage = try memory.data(
                        byteOffset: .init(msgPtr),
                        length: .init(msgLen)
                    )

                    let key = try memory.data(
                        byteOffset: .init(keyPtr),
                        length: .init(keyLen)
                    )

                    let iv = try memory.data(
                        byteOffset: .init(ivPtr),
                        length: .init(ivLen)
                    )

                    var keySize = kCCKeySizeAES128

                    if key.count == kCCKeySizeAES128 {
                        keySize = kCCKeySizeAES128
                    } else if key.count == kCCKeySizeAES192 {
                        keySize = kCCKeySizeAES192
                    } else if key.count == kCCKeySizeAES256 {
                        keySize = kCCKeySizeAES256
                    } else {
                        keySize = key.count
                    }

                    guard iv.isEmpty || iv.count == kCCBlockSizeAES128 else {
                        throw ModuleClient.Error.unknown(msg: "block size not equal to aes128: \(iv.count)")
                    }

                    var outLength = 0
                    var outBytes = [UInt8](repeating: 0, count: encryptedMessage.count + kCCBlockSizeAES128)

                    let status = encryptedMessage.withUnsafeBytes { msgPtr in
                        key.withUnsafeBytes { keyPtr in
                            iv.withUnsafeBytes { ivPtr in
                                CCCrypt(
                                    CCOperation(kCCDecrypt),
                                    CCAlgorithm(kCCAlgorithmAES),
                                    CCOptions(kCCOptionPKCS7Padding),
                                    keyPtr.baseAddress,
                                    keySize,
                                    ivPtr.baseAddress,
                                    msgPtr.baseAddress,
                                    msgPtr.count,
                                    &outBytes,
                                    outBytes.count,
                                    &outLength
                                )
                            }
                        }
                    }

                    guard status == kCCSuccess else {
                        throw ModuleClient.Error.unknown(msg: "decryption failed with status: \(status)")
                    }

                    return alloc.add(Data(bytes: outBytes, count: outLength))
                }
            }
        }
    }
}
