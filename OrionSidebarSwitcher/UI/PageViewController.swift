//
//  PageViewController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class PageViewController: NSViewController {
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    var focusedWorkspaceChangeWatcher: AnyCancellable?
    /// The watcher that detects when the selected tab of the focused workspace changes
    var selectedTabChangeWatcher: AnyCancellable?
    /// The watcher that detects when the selected tab's details change
    var selectedTabDetailsChangeWatcher: AnyCancellable?

    /// The view responsible for showing the primary image
    var imageView: NSImageView!
    /// The view responsible for showing the primary text
    var textView: NSTextView!

    /// A weak reference to the current tab
    weak var currentTab: TabItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the image view
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = imageView
        view.addSubview(imageView)

        // Create the text view
        let label = NSTextView()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 20, weight: .bold)
        self.textView = label
        view.addSubview(label)

        // Constrain them
        NSLayoutConstraint.activate([
            // keep the image view to 100x100
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            // center align the image
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // put the label 30 points below the image
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),

            // center align the label
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.widthAnchor.constraint(equalTo: view.widthAnchor),
            label.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    deinit {
        focusedWorkspaceChangeWatcher?.cancel()
        selectedTabChangeWatcher?.cancel()
    }

    /// Sets up the page view controller's listeners
    func setup() {
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceChangeWatcher,
            call: self.focusedWorkspaceDidChange()
        )
    }

    /// A function called whenever the focused workspace changes
    func focusedWorkspaceDidChange() {
        watch(
            attribute: wsGroupManager.currentWorkspace().$selectedTabId,
            storage: &selectedTabChangeWatcher,
            call: self.selectedTabDidChange()
        )
    }

    /// A function called whenever the selected tab of the focused workspace changes
    func selectedTabDidChange() {
        // Update the current tab
        currentTab = wsGroupManager.currentWorkspaceTab()

        watch(
            attribute: currentTab!.objectWillChange,
            storage: &selectedTabDetailsChangeWatcher,
            call: self.updateUIToCurrentTab()
        )
    }

    /// Updates the UI to be accurate to that of the current tab
    func updateUIToCurrentTab() {
        guard let currentTab else { return }

        // Update the UI
        imageView.image = currentTab.icon
        textView.string = currentTab.name
    }
}
