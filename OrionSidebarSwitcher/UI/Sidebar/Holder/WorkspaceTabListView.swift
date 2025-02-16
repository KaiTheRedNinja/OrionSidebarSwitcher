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

    /// The text label for the workspace's title
    var titleView: NSTextField!

    /// The view containing the pinned tabs
    var pinnedTabsView: NSView!

    /// The view containing the normal tabs
    var normalTabsView: NSView!

    override var isFlipped: Bool { true }

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        self.titleView = NSTextField()
        titleView.stringValue = workspace.name
        titleView.textColor = .gray
        titleView.backgroundColor = .clear
        titleView.isEditable = false
        titleView.font = .boldSystemFont(ofSize: 12)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.drawsBackground = false
        titleView.isBordered = false
        titleView.isSelectable = false
        titleView.lineBreakMode = .byTruncatingMiddle
        titleView.usesSingleLineMode = true
        titleView.maximumNumberOfLines = 0
        addSubview(titleView)

        self.pinnedTabsView = NSView()
        pinnedTabsView.wantsLayer = true
        pinnedTabsView.layer?.backgroundColor = .init(red: 0, green: 1, blue: 0, alpha: 1)
        addSubview(pinnedTabsView)

        self.normalTabsView = NSView()
        normalTabsView.wantsLayer = true
        normalTabsView.layer?.backgroundColor = .init(red: 0, green: 0, blue: 1, alpha: 1)
        addSubview(normalTabsView)
    }

    override func layout() {
        let titleViewHeight: CGFloat = 30

        // title view at the top
        titleView.frame = .init(
            x: 0,
            y: 0,
            width: self.bounds.width,
            height: titleViewHeight
        )

        // pinned tabs view right below
        pinnedTabsView.frame = .init(
            x: 0,
            y: titleViewHeight,
            width: self.bounds.width,
            height: 100
        )

        // normal tabs view all the way down
        normalTabsView.frame = .init(
            x: 0,
            y: titleViewHeight + 100,
            width: self.bounds.width,
            height: self.bounds.height - 100 - titleViewHeight
        )
    }
}
