//
//  MainWindowController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// The controller for the primary window
class MainWindowController: NSWindowController {
    /// The `NSSplitView`'s controller, at the root of this window
    var splitViewController: NSSplitViewController!
    /// The view controller for the sidebar
    var sidebarViewController: SidebarViewController!
    /// The view controller for the page
    var pageViewController: PageViewController!

    /// The manager for this window's `WorkspaceGroup`
    var wsGroupManager: WorkspaceGroupManager!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Set itself as the window's toolbar delegate, and set up the toolbar
        let toolbar = NSToolbar()
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
        window?.toolbarStyle = .unified
        window?.title = "Orion Sidebar Switcher"

        // Set the window's frame to something more browser-like
        window?.setContentSize(.init(width: 900, height: 600))
        window?.minSize = .init(width: 580, height: 400)

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

        // prevent the sidebar from becoming too wide or thin
        splitVC.splitViewItems[0].maximumThickness = 350
        splitVC.splitViewItems[0].minimumThickness = 92

        self.splitViewController = splitVC
        self.sidebarViewController = sidebarVC
        self.pageViewController = pageVC

        // Set up the workspace group's manager, and provide
        // references to the sidebar and page view controllers
        let wsgManager = WorkspaceGroupManager(workspaceGroup: .sampleWorkspaceGroup())
        self.wsGroupManager = wsgManager
        self.sidebarViewController.wsGroupManager = wsgManager
        self.pageViewController.wsGroupManager = wsgManager

        // Inform the sidebar and page view contollers to set up, now that the workspace group manager
        // has been passed to them
        self.sidebarViewController.setup()
        self.pageViewController.setup()

        // unfocus the default focused text field
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(nil)
        }
    }

    @objc
    func toggleSidebar() {
        splitViewController.toggleSidebar(self)
    }
}
