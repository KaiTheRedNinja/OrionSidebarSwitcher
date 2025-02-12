//
//  Workspace.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// An object which holds the data associated with a workspace
class Workspace: Identifiable {
    /// A unique identifier for the workspace
    var id: UUID = .init()

    /// The name of the workspace
    var name: String
    /// The icon for the workspace
    var icon: NSImage
    /// The pinned tabs of this workspace
    var pinnedTabs: [TabItem]
    /// The unpinned/regular tabs of this workspace
    var regularTabs: [TabItem]

    /// Creates a workspace from its name, icon, pinned and unpinned tabs
    init(
        id: UUID = .init(),
        name: String,
        icon: NSImage,
        pinnedTabs: [TabItem],
        regularTabs: [TabItem]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.pinnedTabs = pinnedTabs
        self.regularTabs = regularTabs
    }

    /// A factory method which creates a "Blank Workspace" workspace, which contains one
    /// untitled pinned tab and three untitled regular tabs. Calling this function repeatedly
    /// will produce `Workspace`s with identical `name`s, `icon`s, and tab detauls, but
    /// different `id`s and tab `id`s.
    static func blankWorkspace() -> Workspace {
        .init(
            name: "Blank Workspace",
            icon: defaultIcon,
            pinnedTabs: [.untitledTab()],
            regularTabs: (0..<3).map { _ in .untitledTab() }
        )
    }

    /// The default icon for a workspace
    static let defaultIcon: NSImage = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Tab Icon")!
}
