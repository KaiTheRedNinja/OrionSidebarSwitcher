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

    /// How much padding the contents have between the edge of the view, and each other
    var padding: CGFloat = 6

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

    override var isFlipped: Bool { true }

    override func layout() {
        // How wide the content is, accounting for padding
        let contentWidth = self.bounds.width - padding*2

        // title view at the top. We do manual adjustment so that
        // the view appears vertically centered
        let titleViewTextHeight: CGFloat = 15
        let titleViewHeight: CGFloat = 18
        titleView.frame = .init(
            x: padding,
            y: (titleViewHeight-titleViewTextHeight)/2 + padding,
            width: contentWidth,
            height: titleViewTextHeight
        )

        // pinned tabs view right below
        let pinnedTabsViewHeight = pinnedTabsView.idealHeight(forWidth: contentWidth)
        pinnedTabsView.frame = .init(
            x: padding,
            y: titleView.frame.maxY + padding,
            width: contentWidth,
            height: pinnedTabsViewHeight
        )
        pinnedTabsView.layout()

        // normal tabs view all the way down
        normalTabsView.frame = .init(
            x: padding,
            y: pinnedTabsView.frame.maxY + padding,
            width: contentWidth,
            height: self.bounds.height - pinnedTabsView.frame.maxY - padding
        )
    }
}
