//
//  SidebarViewController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class SidebarViewController: NSViewController {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The view for the workspace switcher view
    var workspaceSwitcherView: NSView!
    /// The view for the workspaces' content, which contains and aligns several workspace views
    var workspaceGroupHolderView: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load and configure the switcher view
        let switcherView = NSView()
        switcherView.translatesAutoresizingMaskIntoConstraints = false
        switcherView.wantsLayer = true
        switcherView.layer?.backgroundColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
        self.workspaceSwitcherView = switcherView
        view.addSubview(switcherView)

        // Load and configure the holder view
        let holderView = NSView()
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.wantsLayer = true
        holderView.layer?.backgroundColor = .init(red: 0, green: 0, blue: 1, alpha: 1)
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
    }
}
