//
//  NettyApp.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI

@main
struct NettyApp: App {
    
    @State private var userSignedIn: Bool = false // Is signed in logic
    
    var body: some Scene {
        WindowGroup {
            if userSignedIn {
//                HomeView()
            } else {
                SignUpView()
            }
        }
    }
}