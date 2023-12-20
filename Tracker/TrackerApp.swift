//
//  TrackerApp.swift
//  Tracker
//
//  Created by Dylan Elliott on 21/12/2023.
//

import SwiftUI

@main
struct TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
//        .fixedSize(horizontal: true, vertical: false)
    }
}
