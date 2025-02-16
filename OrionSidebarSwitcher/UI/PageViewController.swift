//
//  PageViewController.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class PageViewController: NSViewController {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    private var focusedWorkspaceChangeWatcher: AnyCancellable?
    /// The watcher that detects when the focused tab changes
    private var focusedTabChangeWatcher: AnyCancellable?
    /// The watcher that detects when the focused tab's attributes change
    private var focusedTabAttributeWatcher: AnyCancellable?

    /// The view responsible for showing the primary image
    private var imageView: NSImageView!
    /// The view responsible for showing the primary text
    private var textView: NSTextView!

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
        label.isEditable = false
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
        focusedTabChangeWatcher?.cancel()
        focusedTabAttributeWatcher?.cancel()
    }

    /// Sets up the page view controller's listeners
    func setup() {
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceChangeWatcher
        ) { [weak self] focusedWorkspaceId in
            guard let self else { return }

            guard let focusedWorkspace = wsGroupManager.workspaceGroup.workspaces
                .first(where: { $0.id == focusedWorkspaceId })
            else { return }

            watch(
                attribute: focusedWorkspace.$selectedTabId,
                storage: &focusedTabChangeWatcher
            ) { [weak self] selectedTabId in
                guard let self else { return }

                guard let selectedTab = focusedWorkspace.allTabs
                    .first(where: { $0.id == selectedTabId })
                else { return }

                // Update the UI
                imageView.image = selectedTab.icon
                textView.string = selectedTab.name
            }
        }
    }
}
