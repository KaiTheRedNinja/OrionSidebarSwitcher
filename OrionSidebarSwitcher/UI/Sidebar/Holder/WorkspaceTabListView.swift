//
//  WorkspaceTabListView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

/// A view that contains the contents of a workspace tab
class WorkspaceTabListView: NSView {
    /// The workspace that this view lists tabs for. This is a strong reference so that we can still access the ID
    /// after the workspace is removed from the manager.
    var workspace: Workspace!

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        wantsLayer = true
        layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 0.1)
        layer?.borderWidth = 4
        layer?.borderColor = NSColor.blue.cgColor

        let textView = NSTextView()
        textView.string = workspace.name
        textView.textColor = .gray
        addSubview(textView)
        textView.frame = .init(x: 0, y: 0, width: 100, height: 100)
    }
}
