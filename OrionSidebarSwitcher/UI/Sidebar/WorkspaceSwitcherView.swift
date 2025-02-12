//
//  WorkspaceSwitcherView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class WorkspaceSwitcherView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// Sets up the workspace switcher view's UI and listeners
    func setup() {
        wantsLayer = true
        layer?.backgroundColor = .init(red: 0, green: 0, blue: 1, alpha: 1)
    }
}
