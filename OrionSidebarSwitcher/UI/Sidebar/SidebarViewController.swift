//
//  SidebarViewController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

/// A view controller that manages the views of the sidebar
class SidebarViewController: NSViewController {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The view for the workspace switcher view
    var workspaceSwitcherView: WorkspaceSwitcherView!
    /// The view for the workspaces' content, which contains and aligns several workspace views
    var workspaceGroupHolderView: WorkspaceGroupHolderView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load and configure the switcher view
        let switcherView = WorkspaceSwitcherView()
        switcherView.translatesAutoresizingMaskIntoConstraints = false
        self.workspaceSwitcherView = switcherView
        view.addSubview(switcherView)

        // Load and configure the holder view
        let holderView = WorkspaceGroupHolderView()
        holderView.translatesAutoresizingMaskIntoConstraints = false
        self.workspaceGroupHolderView = holderView
        view.addSubview(holderView)

        // Constrain them
        NSLayoutConstraint.activate([
            // constrain switcher view's height and bounds
            switcherView.heightAnchor.constraint(equalToConstant: 30),
            switcherView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switcherView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            switcherView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            // note: we use the safe area top anchor, because the view technically goes up
            // to the very top of the window

            // constrain holder view's bounds
            holderView.topAnchor.constraint(equalTo: switcherView.bottomAnchor),
            holderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            holderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            holderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Sets up the sidebar view controller's listeners
    func setup() {
        workspaceSwitcherView.wsGroupManager = wsGroupManager
        workspaceGroupHolderView.wsGroupManager = wsGroupManager
        workspaceSwitcherView.setup()
        workspaceGroupHolderView.setup()
    }
}
