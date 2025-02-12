//
//  AppDelegate.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

/// Watches a published attribute, by storing it in a cancellable and calling a closure during publishes
func watch<P: Publisher>(
    attribute: P,
    storage: inout AnyCancellable?,
    call: @escaping @autoclosure () -> Void
) where P.Failure == Never {
    // Cancel whatever is in the storage
    storage?.cancel()
    // Create a new watcher
    storage = attribute.sink { _ in
        call()
    }
    // Call the function as the first trigger
    call()
}
