//
//  WorkspaceIconView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

/// A view, used within the switcher, that represents a single workspace
class WorkspaceIconView: NSView {
    /// The workspace that this icon is for. This is a strong reference so that we can still access the ID
    /// after the workspace is removed from the manager.
    var workspace: Workspace!
    /// The interaction delegate
    weak var interactionDelegate: WorkspaceIconInteractionDelegate?

    /// The watcher for when the workspace's icon changes
    private var workspaceIconWatcher: AnyCancellable?
    /// How this icon was last rendered
    private var renderingStyle: WorkspaceIconRenderingStyle = .unselectedCompact
    /// The view used to display the view's icon in "expanded" mode
    private var iconView: NSImageView!
    /// The view used to display a dot in "contracted" mode
    private var dotView: CircleView!

    /// The minimum width of a WorkspaceIconView in compact mode
    static let minimumCompactWidth: CGFloat = 16
    /// The minimum width of a WorkspaceIconView before it enters compact mode
    static let minimumExpandedWidth: CGFloat = 22
    /// The maximum width of a WorkspaceIconView. This is also the distance between the centers
    /// of two consecutive WorkspaceIconViews
    static let maximumExpandedWidth: CGFloat = 30

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.anchorPoint = CGPoint(x: 1, y: 1)

        // create both views
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .gray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(iconView)

        dotView = CircleView()
        dotView.circleColor = .gray
        dotView.circleRadius = 3
        dotView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(dotView)

        // make both views invisible
        iconView.alphaValue = 0
        dotView.alphaValue = 0

        // constrain their frames to be equal to this view's
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 21),
            iconView.widthAnchor.constraint(equalToConstant: 21),

            dotView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            dotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            dotView.heightAnchor.constraint(equalTo: self.heightAnchor),
            dotView.widthAnchor.constraint(equalTo: self.widthAnchor)
        ])
    }

    /// Sets up the icon watcher
    func setup() {
        guard let workspace else { return }
        watch(
            attribute: workspace.$icon,
            storage: &workspaceIconWatcher
        ) { icon in
            self.iconView.image = icon
        }
    }

    // MARK: Interaction
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseEntered(workspace.id)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseExited(workspace.id)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseClicked(workspace.id)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()

        let deleteItem = NSMenuItem()
        deleteItem.image = .trash
        deleteItem.title = "Delete \"\(workspace.name)\""
        deleteItem.action = #selector(deleteWorkspace)
        deleteItem.target = self
        menu.items.append(deleteItem)

        let switchIconsSubmenu = NSMenu()
        for image in NSImage.tabIconOptions {
            let imageItem = NSMenuItem()
            imageItem.image = image
            imageItem.title = "Switch Icon"
            imageItem.action = #selector(switchIcon(_:))
            imageItem.target = self
            switchIconsSubmenu.items.append(imageItem)
        }

        let switchItem = NSMenuItem()
        switchItem.image = workspace.icon
        switchItem.title = "Switch workspace icon"
        switchItem.submenu = switchIconsSubmenu
        menu.items.append(switchItem)

        return menu
    }

    @objc
    func deleteWorkspace() {
        interactionDelegate?.workspaceDeleteRequested(workspace.id)
    }

    @objc
    func switchIcon(_ sender: Any?) {
        guard let sender = sender as? NSMenuItem, let image = sender.image else { return }

        // set the icon
        workspace.icon = image
    }

    // MARK: Layout
    /// Lays out the subviews according to a rendering style. If the `newRenderingStyle` is
    /// different from the `renderingStyle`, this change is animated. If not, it is instant.
    func layout(
        renderingStyleChangedTo newRenderingStyle: WorkspaceIconRenderingStyle
    ) {
        // determine if we should animate, and defer updating the rendering style
        let shouldAnimate = newRenderingStyle != renderingStyle
        defer { renderingStyle = newRenderingStyle }

        let hiddenTransform: (CATransform3D, CGFloat) = (CATransform3DMakeScale(0, 0, 1), 0)
        let shownTransform: (CATransform3D, CGFloat) = (CATransform3DIdentity, 1)

        // determine the new scales and opacities for each
        // the only time the dot is shown is when the view is compact
        let iconViewTransform = newRenderingStyle == .unselectedCompact ? hiddenTransform : shownTransform
        let iconViewColor: NSColor = newRenderingStyle == .selected ? .controlAccentColor : .secondaryLabelColor
        let dotViewTransform =  newRenderingStyle != .unselectedCompact ? hiddenTransform : shownTransform

        // apply it, with an animation if needed
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                iconView.animator().alphaValue = iconViewTransform.1
                iconView.animator().contentTintColor = iconViewColor
                dotView.animator().alphaValue = dotViewTransform.1
            }
        } else {
            iconView.alphaValue = iconViewTransform.1
            iconView.contentTintColor = iconViewColor
            dotView.alphaValue = dotViewTransform.1
        }

        // if we went from unselected to selected, we undergo the click animation
        if newRenderingStyle == .selected && shouldAnimate {
            click()
        }
    }

    /// Animates a shake effect for when the icon is clicked
    func click() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: frame.minX, y: frame.minY)
        animation.toValue = CGPoint(x: frame.minX, y: frame.minY+2)
        layer?.add(animation, forKey: "position")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Remove existing tracking areas
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        // Define tracking area
        let trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )

        // Add tracking area
        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A delegate which is informed of interactions within the delegate
protocol WorkspaceIconInteractionDelegate: AnyObject {
    /// The mouse has entered the view, marking the start of a hover
    func workspaceIconMouseEntered(_ workspaceId: Workspace.ID)
    /// The mouse has exited the view, marking the end of a hover
    func workspaceIconMouseExited(_ workspaceId: Workspace.ID)
    /// The mouse has clicked on the workspace icon
    func workspaceIconMouseClicked(_ workspaceId: Workspace.ID)
    /// The user has requested to delete the workspace
    func workspaceDeleteRequested(_ workspaceId: Workspace.ID)
}

/// How the workspace icon is rendered
enum WorkspaceIconRenderingStyle {
    /// The icon is selected. Should be rendered uncompacted and with accentColor
    case selected
    /// The icon is not selected but also not compact. Should be rendered uncompacted
    /// and gray. This may be used when the icon is being hovered on.
    case unselectedExpanded
    /// The icon is not selected and is compact. Should be rendered as a dot.
    case unselectedCompact
}
