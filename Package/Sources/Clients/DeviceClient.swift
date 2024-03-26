//
//  DeviceClient.swift
//
//
//  Created by ErrorErrorError on 11/29/23.
//
//

struct DeviceClient: _Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
    }
}
