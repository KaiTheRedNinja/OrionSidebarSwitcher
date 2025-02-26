//
//  NSImage+defaults.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

import Cocoa

/// A centralised spot to create SF Symbol-based `NSImages`
extension NSImage {
    // UI icons
    static let plusCircle = NSImage(systemSymbolName: "plus.circle.dashed", accessibilityDescription: "plus")
    static let trash = NSImage(systemSymbolName: "trash", accessibilityDescription: "trash")
    static let sidebarLeft = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")

    // Tab/workspace icons
    static let globe = NSImage(systemSymbolName: "globe", accessibilityDescription: "Tab Icon")!
    static let macwindow = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Tab Icon")!
    static let macbook = NSImage(systemSymbolName: "macbook", accessibilityDescription: "Tab Icon")!
    static let cake = NSImage(systemSymbolName: "birthday.cake.fill", accessibilityDescription: "Tab Icon")!
}
