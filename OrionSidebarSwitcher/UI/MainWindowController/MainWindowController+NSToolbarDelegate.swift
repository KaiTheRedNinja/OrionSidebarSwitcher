//
//  MainWindowController+NSToolbarDelegate.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

extension MainWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.sidebarToggleButton]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        // the default items are the allowed items
        toolbarAllowedItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        // This toolbar only contains a sidebar toggle, so we don't allow any other
        // sidebar items to be shown
        guard case .sidebarToggleButton = itemIdentifier else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.image = .sidebarLeft
        item.title = "Toggle Sidebar"
        item.action = #selector(toggleSidebar)
        item.isNavigational = true

        return item
    }
}

extension NSToolbarItem.Identifier {
    /// The toggle button for the sidebar
    static let sidebarToggleButton = NSToolbarItem.Identifier("sidebarToggleButton")
}
