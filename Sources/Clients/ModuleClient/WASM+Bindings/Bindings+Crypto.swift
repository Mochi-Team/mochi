//
//  Bindings+Crypto.swift
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
extension ModuleClient.WAInstance {
    func cryptoImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "crypto") {
            WasmInstance.Function("crypto_get_data_len") { [self] (
                hostPtr: Int32
            ) -> Int32 in
                hostBindings.crypto_get_data_len(host_data_ptr: hostPtr)
            }

            WasmInstance.Function("crypto_get_data") { [self] (
                hostPtr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostBindings.crypto_get_data(
                    host_data_ptr: hostPtr,
                    buf_ptr: bufPtr,
                    buf_len: bufLen
                )
            }

            WasmInstance.Function("crypto_base64_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                hostBindings.crypto_base64_parse(
                    value_ptr: valuePtr,
                    value_len: valueLen
                )
            }

            WasmInstance.Function("crypto_base64_string") { [self] (
                bytesPtr: Int32,
                bytesLen: Int32
            ) -> Int32 in
                hostBindings.crypto_base64_string(
                    bytes_ptr: bytesPtr,
                    bytes_len: bytesLen
                )
            }

            WasmInstance.Function("crypto_utf8_parse") { [self] (
                valuePtr: Int32,
                valueLen: Int32
            ) -> Int32 in
                hostBindings.crypto_utf8_parse(
                    value_ptr: valuePtr,
                    value_len: valueLen
                )
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
                hostBindings.crypto_pbkdf2(
                    hash_algorithm: .init(hashFunction),
                    password_ptr: passwordPtr,
                    password_len: passwordLen,
                    salt_ptr: saltPtr,
                    salt_len: saltLen,
                    rounds: rounds,
                    key_count: keyCount
                )
            }

            WasmInstance.Function("crypto_md5_hash") { [self] (
                inputPtr: Int32,
                inputLen: Int32
            ) -> Int32 in
                hostBindings.crypto_md5_hash(input_ptr: .init(inputPtr), input_len: .init(inputLen))
            }

            WasmInstance.Function("crypto_generate_random_bytes") { [self] (
                count: Int32
            ) -> Int32 in
                hostBindings.crypto_generate_random_bytes(count: count)
            }

            WasmInstance.Function("crypto_aes_encrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                hostBindings.crypto_aes_encrypt(
                    msg_buf_ptr: msgPtr,
                    msg_buf_len: msgLen,
                    key_ptr: keyPtr,
                    key_len: keyLen,
                    iv_ptr: ivPtr,
                    iv_len: ivLen
                )
            }

            WasmInstance.Function("crypto_aes_decrypt") { [self] (
                msgPtr: Int32,
                msgLen: Int32,
                keyPtr: Int32,
                keyLen: Int32,
                ivPtr: Int32,
                ivLen: Int32
            ) -> Int32 in
                hostBindings.crypto_aes_decrypt(
                    encrypted_msg_ptr: msgPtr,
                    encrypted_msg_len: msgLen,
                    key_ptr: keyPtr,
                    key_len: keyLen,
                    iv_ptr: ivPtr,
                    iv_len: ivLen
                )
            }
        }
    }
}

// swiftlint:enable closure_parameter_position
