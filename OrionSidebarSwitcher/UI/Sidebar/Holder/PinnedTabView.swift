//
//  PinnedTabView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 17/2/25.
//

import Cocoa
import Combine

class PinnedTabView: NSView {
    var tabItem: TabItem!
    var isSelected: Bool!

    /// The watcher for when the tab's icon changes
    private var tabIconWatcher: AnyCancellable?
    /// The view used to display the tab's icon
    private var iconView: NSImageView!

    static let tabItemHeight: CGFloat = 40

    func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.separatorColor.cgColor
        layer?.cornerRadius = 6

        // Create the icon view
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .gray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = tabItem.icon
        self.addSubview(iconView)

        // Constrain the icon view
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            iconView.widthAnchor.constraint(equalToConstant: 28)
        ])

        // Watch its icon for changes
        watch(
            attribute: tabItem.$icon,
            storage: &tabIconWatcher,
            call: { image in
                self.iconView.image = image
            }
        )
    }
}
