//
//  WorkspaceGroupHolderView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class WorkspaceGroupHolderView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        wantsLayer = true
        layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 0.1)
    }
}
