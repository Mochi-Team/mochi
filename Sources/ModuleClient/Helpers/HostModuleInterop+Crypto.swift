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

// swiftlint:disable function_parameter_count
extension HostModuleInterop {
    func crypot_get_data_len(
        host_data_ptr: Int32
    ) -> Int32 {
        hostAllocations.withValue { alloc in
            guard let data = alloc[host_data_ptr] as? Data else {
                return 0
            }
            return .init(data.count)
        }
    }

    func crypto_get_data(
        host_data_ptr: Int32,
        buf_ptr: Int32,
        buf_len: Int32
    ) {
        hostAllocations.withValue { alloc in
            guard let data = alloc[host_data_ptr] as? Data else {
                return
            }

            try? memory.write(
                with: data.dropLast(data.count - Int(buf_len)),
                byteOffset: .init(buf_ptr)
            )
        }
    }

    func crypto_base64_parse(
        value_ptr: Int32,
        value_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let value = try memory.string(
                byteOffset: .init(value_ptr),
                length: .init(value_len)
            )

            return alloc.add(Data(base64Encoded: value) ?? .init())
        }
    }

    func crypto_utf8_parse(
        value_ptr: Int32,
        value_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let value = try memory.string(
                byteOffset: .init(value_ptr),
                length: .init(value_len)
            )

            return alloc.add(value.data(using: .utf8) ?? .init())
        }
    }

    func crypto_base64_string(
        bytes_ptr: Int32,
        bytes_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let value = try memory.data(
                byteOffset: .init(bytes_ptr),
                length: .init(bytes_len)
            )

            return alloc.add(value.base64EncodedString())
        }
    }

    func crypto_aes_encrypt(
        msg_buf_ptr: Int32,
        msg_buf_len: Int32,
        key_ptr: Int32,
        key_len: Int32,
        iv_ptr: Int32,
        iv_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let message = try memory.data(
                byteOffset: .init(msg_buf_ptr),
                length: .init(msg_buf_len)
            )

            let key = try memory.data(
                byteOffset: .init(key_ptr),
                length: .init(key_len)
            )

            let iv = try memory.data(
                byteOffset: .init(iv_ptr),
                length: .init(iv_len)
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

    func crypto_aes_decrypt(
        encrypted_msg_ptr: Int32,
        encrypted_msg_len: Int32,
        key_ptr: Int32,
        key_len: Int32,
        iv_ptr: Int32,
        iv_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let encryptedMessage = try memory.data(
                byteOffset: .init(encrypted_msg_ptr),
                length: .init(encrypted_msg_len)
            )

            let key = try memory.data(
                byteOffset: .init(key_ptr),
                length: .init(key_len)
            )

            let iv = try memory.data(
                byteOffset: .init(iv_ptr),
                length: .init(iv_len)
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

extension HostModuleInterop {
    public func crypto_pbkdf2(
        hash_algorithm: CCPBKDFAlgorithm,
        password_ptr: Int32,
        password_len: Int32,
        salt_ptr: Int32,
        salt_len: Int32,
        rounds: Int32,
        key_count: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let password = try memory.string(byteOffset: .init(password_ptr), length: .init(password_len))
            let salt = try memory.data(byteOffset: .init(salt_ptr), length: .init(salt_len))

            var derivedKeyData = Data(repeating: 0, count: .init(key_count))
            let derivedCount = derivedKeyData.count

            let status = derivedKeyData.withUnsafeMutableBytes { derivedKeyDataPtr in
                salt.withUnsafeBytes { saltPtr in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        password,
                        password.count,
                        saltPtr.baseAddress,
                        salt.count,
                        hash_algorithm,
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

    public func crypto_generate_random_bytes(
        count: Int32
    ) -> Int32 {
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
}

extension HostModuleInterop {
    public func crypto_md5_hash(
        input_ptr: Int32,
        input_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let data = try memory.data(byteOffset: .init(input_ptr), length: .init(input_len))
            var function = Insecure.MD5()
            function.update(data: data)
            return alloc.add(Data(function.finalize()))
        }
    }
}
