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
    /// The watcher that detects when the focused tab's icon changes
    private var focusedTabIconWatcher: AnyCancellable?
    /// The watcher that detects when the focused tab's title changes
    private var focusedTabTitleWatcher: AnyCancellable?

    /// The view responsible for showing the primary image
    private var imageView: NSImageView!
    /// The view responsible for showing the primary text
    private var textView: NSText!

    /// The KVO object for the text view
    private var textViewKVO: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the image view
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = imageView
        view.addSubview(imageView)

        // Create the text view
        let label = NSText()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.isEditable = true
        label.delegate = self
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

    override func rightMouseUp(with event: NSEvent) {
        let menu = NSMenu()

        for image in NSImage.tabIconOptions {
            let imageItem = NSMenuItem()
            imageItem.image = image
            imageItem.title = "Switch Icon"
            imageItem.action = #selector(switchIcon(_:))
            imageItem.target = self
            menu.items.append(imageItem)
        }

        menu.popUp(positioning: nil, at: .zero, in: self.imageView)
    }

    @objc
    func switchIcon(_ sender: Any?) {
        guard let sender = sender as? NSMenuItem, let image = sender.image else { return }

        // set the icon
        wsGroupManager.currentWorkspaceTab().icon = image
    }

    deinit {
        focusedWorkspaceChangeWatcher?.cancel()
        focusedTabChangeWatcher?.cancel()
        focusedTabIconWatcher?.cancel()
        focusedTabTitleWatcher?.cancel()
    }

    /// Sets up the page view controller's listeners
    func setup() {
        // watch the focused workspace id
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceChangeWatcher
        ) { [weak self] focusedWorkspaceId in
            guard let self else { return }

            // get the focused workspace
            guard let focusedWorkspace = wsGroupManager.workspaceGroup.workspaces
                .first(where: { $0.id == focusedWorkspaceId })
            else { return }

            // watch the focused workspace's selected tab id
            watch(
                attribute: focusedWorkspace.$selectedTabId,
                storage: &focusedTabChangeWatcher
            ) { [weak self] selectedTabId in
                guard let self else { return }

                // get the selected tab
                guard let selectedTab = focusedWorkspace.allTabs
                    .first(where: { $0.id == selectedTabId })
                else { return }

                // Update the UI
                watch(attribute: selectedTab.$icon, storage: &focusedTabIconWatcher) { [weak self] image in
                    self?.imageView.image = image
                }
                watch(attribute: selectedTab.$name, storage: &focusedTabTitleWatcher) { [weak self] name in
                    self?.textView.string = name
                }
            }
        }
    }
}

extension PageViewController: NSTextDelegate {
    func textDidChange(_ notification: Notification) {
        // if the text view contains a newline, finish editing
        if textView.string.contains("\n") { view.window?.makeFirstResponder(nil) }
        wsGroupManager.currentWorkspaceTab().name = textView.string.replacingOccurrences(of: "\n", with: "")
    }
}
