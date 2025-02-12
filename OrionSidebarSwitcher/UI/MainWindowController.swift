//
//  MainWindowController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class MainWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        print("Window loaded!")

        // Set itself as the window's toolbar delegate, and set up the toolbar
        let toolbar = NSToolbar()
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
        window?.toolbarStyle = .unified
        window?.title = "Orion Sidebar Switcher"

        // Set the window's frame to something more browser-like
        window?.setContentSize(.init(width: 900, height: 600))
    }
}

extension MainWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.sidebarToggleButton]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar) // the default items are the allowed items
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
        item.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")
        item.title = "Toggle Sidebar"
        item.action = #selector(toggleSidebar)
        item.isNavigational = true

        return item
    }

    @objc
    func toggleSidebar() {
        print("Toggle Sidebar Pressed!")
    }
}

extension NSToolbarItem.Identifier {
    /// The toggle button for the sidebar
    static let sidebarToggleButton = NSToolbarItem.Identifier("sidebarToggleButton")
}
