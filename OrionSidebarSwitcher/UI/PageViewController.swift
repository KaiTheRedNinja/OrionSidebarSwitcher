//
//  PageViewController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa

class PageViewController: NSViewController {
    weak var wsGroupManager: WorkspaceGroupManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        print("Sidebar view controller loaded")
    }
}
