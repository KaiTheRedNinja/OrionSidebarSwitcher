//
//  TabItem.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// An object which holds the data associated with a tab
class TabItem: Identifiable, ObservableObject {
    /// A unique identifier for the tab item
    let id: UUID

    /// The name of the tab
    @Published var name: String
    /// The icon for the tab
    @Published var icon: NSImage

    /// Creates a tab item from its name and icon
    init(id: UUID = .init(), name: String, icon: NSImage) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    /// A factory method which creates an "Untitled Tab" tab item. Calling this function repeatedly
    /// will produce `TabItem`s with identical `name`s and `icon`s, but different `id`s.
    static func untitledTab() -> TabItem {
        .init(
            name: "Untitled Tab",
            icon: defaultIcon
        )
    }

    /// The default icon for a tab
    static let defaultIcon: NSImage = .globe
}
