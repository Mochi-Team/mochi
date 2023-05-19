//
//  AppDelegate.swift
//  mochi
//
//  Created by ErrorErrorError on 5/19/23.
//  
//

#if os(iOS)
import App
import Architecture
import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    let store = StoreOf<AppFeature.Reducer>(
        initialState: .init(),
        reducer: AppFeature.Reducer()
    )

    var viewStore: ViewStore<Void, AppFeature.Action> {
        ViewStore(store.stateless)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        viewStore.send(.internal(.appDelegate(.didFinishLaunching)))
        return true
    }
}
#endif
