//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct WasmInterpreter: Shared {
    var dependencies: any Dependencies {
        CWasm3()
    }

    var cSettings: [CSetting] {
        CSetting.define("APPLICATION_EXTENSION_API_ONLY", to: "YES")
    }
}

struct CWasm3: Product, Target {
    var targetType: TargetType {
        .binary(
            .remote(
                url: "https://github.com/shareup/cwasm3/releases/download/v0.5.2/CWasm3-0.5.0.xcframework.zip",
                checksum: "a2b0785be1221767d926cee76b087f168384ec9735b4f46daf26e12fae2109a3"
            )
        )
    }
}
