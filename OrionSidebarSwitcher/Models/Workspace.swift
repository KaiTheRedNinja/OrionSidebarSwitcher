//
//  Workspace.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// An object which holds the data associated with a workspace
class Workspace: Identifiable, ObservableObject {
    /// A unique identifier for the workspace
    let id: UUID

    /// The name of the workspace
    @Published var name: String
    /// The icon for the workspace
    @Published var icon: NSImage
    /// The pinned tabs of this workspace
    @Published var pinnedTabs: [TabItem]
    /// The unpinned/regular tabs of this workspace
    @Published var regularTabs: [TabItem]
    /// The ID of the selected tab
    @Published var selectedTabId: TabItem.ID?

    /// Creates a workspace from its name, icon, pinned/unpinned tabs, and selected tab ID
    init(
        id: UUID = .init(),
        name: String,
        icon: NSImage,
        pinnedTabs: [TabItem],
        regularTabs: [TabItem],
        selectedTabID: TabItem.ID?
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.pinnedTabs = pinnedTabs
        self.regularTabs = regularTabs
        self.selectedTabId = selectedTabID
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
            regularTabs: (0..<3).map { _ in .untitledTab() },
            selectedTabID: nil
        )
    }

    /// The default icon for a workspace
    static let defaultIcon: NSImage = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Tab Icon")!
}
