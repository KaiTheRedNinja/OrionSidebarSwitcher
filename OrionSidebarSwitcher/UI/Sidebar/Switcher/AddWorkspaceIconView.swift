//
//  AddWorkspaceIconView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 16/2/25.
//

import Cocoa
import Combine

/// A view, used within the switcher, that represents a single workspace
class AddWorkspaceIconView: NSView {
    /// The interaction delegate
    weak var interactionDelegate: AddWorkspaceInteractionDelegate?

    /// The plus icon image view
    private var iconView: NSImageView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.anchorPoint = CGPoint(x: 1, y: 1)

        // create the icon view
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .labelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = .plusCircle
        self.addSubview(iconView)

        // constrain the icon view's frame to be equal to this view's
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        interactionDelegate?.workspaceAdditionRequested()
    }
}

/// A delegate which is informed of interactions within the delegate
protocol AddWorkspaceInteractionDelegate: AnyObject {
    /// The plus button has been pressed
    func workspaceAdditionRequested()
}
