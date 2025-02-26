//
//  NSImage+defaults.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

import Cocoa

// swiftlint:disable line_length

/// A centralised spot to create SF Symbol-based `NSImages`
extension NSImage {
    // UI icons
    static let plusCircle = NSImage(systemSymbolName: "plus.circle.dashed", accessibilityDescription: "plus")
    static let trash = NSImage(systemSymbolName: "trash", accessibilityDescription: "trash")
    static let sidebarLeft = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")
    static let edit = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Edit")!

    // Tab/workspace icons
    static let globe = NSImage(systemSymbolName: "globe", accessibilityDescription: "Tab Icon")!
    static let macwindow = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Tab Icon")!
    static let macbook = NSImage(systemSymbolName: "macbook", accessibilityDescription: "Tab Icon")!
    static let cake = NSImage(systemSymbolName: "birthday.cake.fill", accessibilityDescription: "Tab Icon")!
    static let folder = NSImage(systemSymbolName: "folder", accessibilityDescription: "Tab Icon")!
    static let document = NSImage(systemSymbolName: "document", accessibilityDescription: "Tab Icon")!
    static let book = NSImage(systemSymbolName: "book.closed", accessibilityDescription: "Tab Icon")!
    static let branch = NSImage(systemSymbolName: "arrow.trianglehead.branch", accessibilityDescription: "Tab Icon")!
    static let rewindClock = NSImage(systemSymbolName: "clock.arrow.trianglehead.counterclockwise.rotate.90", accessibilityDescription: "Tab Icon")!

    static let tabIconOptions: [NSImage] = [globe, macwindow, macbook, cake, folder, document, book, branch, rewindClock]
}

// swiftlint:enable line_length
