//
//  WorkspaceTabListView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

/// A view that contains the contents of a workspace tab
class WorkspaceTabListView: NSView {
    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        wantsLayer = true
        layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 0.1)
        layer?.borderWidth = 4
        layer?.borderColor = NSColor.blue.cgColor
    }
}
