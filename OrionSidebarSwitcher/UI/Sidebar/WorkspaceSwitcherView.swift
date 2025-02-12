//
//  WorkspaceSwitcherView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class WorkspaceSwitcherView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    private var focusedWorkspaceWatcher: AnyCancellable?
    /// The watcher that detects when the number or order of workspaces change
    /// (eg. workspaces added, removed, rearranged)
    private var workspacesOrderWatcher: AnyCancellable?

    /// Sets up the workspace switcher view's UI and listeners
    func setup() {
        addSeparators()
    }

    /// Adds the separators at the top and bottom of the switcher view
    private func addSeparators() {
        wantsLayer = true

        let topBorder = CALayer()
        topBorder.backgroundColor = NSColor.separatorColor.cgColor
        topBorder.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)

        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = NSColor.separatorColor.cgColor
        bottomBorder.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)

        layer?.addSublayer(topBorder)
        layer?.addSublayer(bottomBorder)
    }
}
