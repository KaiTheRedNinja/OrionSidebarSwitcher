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
    var pinnedTabsView: WorkspacePinnedTabsView!

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
        titleView.isBordered = false
        titleView.isSelectable = false
        titleView.lineBreakMode = .byTruncatingMiddle
        titleView.usesSingleLineMode = true
        addSubview(titleView)

        self.pinnedTabsView = WorkspacePinnedTabsView()
        pinnedTabsView.pinnedTabs = workspace.pinnedTabs
        pinnedTabsView.setup()
        addSubview(pinnedTabsView)

        self.normalTabsView = NSView()
        normalTabsView.wantsLayer = true
        normalTabsView.layer?.backgroundColor = .init(red: 0, green: 0, blue: 1, alpha: 1)
        addSubview(normalTabsView)
    }

    override func layout() {
        // title view at the top. We do manual adjustment so that
        // the view appears vertically centered
        let titleViewTextHeight: CGFloat = 15
        let titleViewHeight: CGFloat = 20
        titleView.frame = .init(
            x: 0,
            y: (titleViewHeight-titleViewTextHeight)/2,
            width: self.bounds.width,
            height: titleViewTextHeight
        )

        // pinned tabs view right below
        let pinnedTabsViewHeight = pinnedTabsView.idealHeight(forWidth: bounds.width)
        pinnedTabsView.frame = .init(
            x: 0,
            y: titleViewHeight,
            width: self.bounds.width,
            height: pinnedTabsViewHeight
        )
        pinnedTabsView.layout()

        // normal tabs view all the way down
        normalTabsView.frame = .init(
            x: 0,
            y: titleViewHeight + pinnedTabsViewHeight,
            width: self.bounds.width,
            height: self.bounds.height - pinnedTabsViewHeight - titleViewHeight
        )
    }
}
