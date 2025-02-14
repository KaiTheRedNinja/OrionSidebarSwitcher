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
    /// The unpinned/regular tabs of this workspace. There must be at least ONE regular tab,
    /// having zero regular tabs is considered invalid state.
    @Published var regularTabs: [TabItem]
    /// The ID of the selected tab. This must correspond with EXACTLY ONE tab in either
    /// ``pinnedTabs`` or ``regularTabs``, corresponding with zero or multiple is considered
    /// invalid state
    @Published var selectedTabId: TabItem.ID

    /// A computed property for all tabs within this workspace. Pinned tabs are first, followed by regular tabs.
    var allTabs: [TabItem] { pinnedTabs + regularTabs }

    /// Creates a workspace from its name, icon, pinned/unpinned tabs, and selected tab ID. If not provided, it defaults
    /// to the first regular tab
    init(
        id: UUID = .init(),
        name: String,
        icon: NSImage,
        pinnedTabs: [TabItem],
        regularTabs: [TabItem],
        selectedTabID: TabItem.ID? = nil
    ) {
        assert(!regularTabs.isEmpty, "At least one regular tab must be provided")
        self.id = id
        self.name = name
        self.icon = icon
        self.pinnedTabs = pinnedTabs
        self.regularTabs = regularTabs
        self.selectedTabId = selectedTabID ?? regularTabs[0].id
    }

    /// A factory method which creates a "Blank Workspace" workspace, which contains one
    /// untitled pinned tab and three untitled regular tabs, with the first unpinned tab selected.
    /// Calling this function repeatedly will produce `Workspace`s with identical `name`s,
    /// `icon`s, and tab detauls, but different `id`s and tab `id`s.
    static func blankWorkspace() -> Workspace {
        let regularTabs = (0..<3).map { _ in TabItem.untitledTab() }

        return .init(
            name: "Blank Workspace",
            icon: defaultIcon,
            pinnedTabs: [.untitledTab()],
            regularTabs: regularTabs,
            selectedTabID: regularTabs[0].id
        )
    }

    /// The default icon for a workspace
    static let defaultIcon: NSImage = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Tab Icon")!
}
