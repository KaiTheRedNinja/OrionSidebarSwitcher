//
//  TabItem.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// An object which holds the data associated with a tab
class TabItem: Identifiable {
    /// A unique identifier for the tab item
    var id: UUID = .init()

    /// The name of the tab
    var name: String

    /// The icon for the tab
    var icon: NSImage

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
            icon: NSImage(systemSymbolName: "globe", accessibilityDescription: "Tab Icon")!
        )
    }
}
