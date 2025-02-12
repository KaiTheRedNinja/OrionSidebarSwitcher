//
//  MainWindowController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class MainWindowController: NSWindowController {
    /// The `NSSplitView`'s controller, at the root of this window
    var splitViewController: NSSplitViewController!
    /// The view controller for the sidebar
    var sidebarViewController: SidebarViewController!
    /// The view controller for the page
    var pageViewController: PageViewController!

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

        // Get the split view controller
        guard let splitVC = self.contentViewController as? NSSplitViewController,
              splitVC.splitViewItems.count == 2,
              let sidebarVC = splitVC.splitViewItems[0].viewController as? SidebarViewController,
              let pageVC = splitVC.splitViewItems[1].viewController as? PageViewController
        else {
            // If the content of this window is not a split view controller, or its contents are incorrect,
            // we error since we can't recover from this state
            fatalError("Split view incorrectly configured")
        }

        self.splitViewController = splitVC
        self.sidebarViewController = sidebarVC
        self.pageViewController = pageVC
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
