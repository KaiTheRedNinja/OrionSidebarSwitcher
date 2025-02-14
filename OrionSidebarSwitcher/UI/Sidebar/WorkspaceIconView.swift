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
    private var dotView: NSTextView!

    /// The minimum width of a WorkspaceIconView before it enters compact mode
    static let minimumExpandedWidth: CGFloat = 48
    /// The maximum width of a WorkspaceIconView. This is also the distance between the centers
    /// of two consecutive WorkspaceIconViews
    static let maximumExpandedWidth: CGFloat = 70

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // create both views
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .gray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        self.addSubview(iconView)

        dotView = NSTextView()
        dotView.string = "⋅"
        dotView.alignment = .center
        dotView.backgroundColor = .clear
        dotView.font = .systemFont(ofSize: 10, weight: .bold)
        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.wantsLayer = true
        self.addSubview(dotView)

        // downscale both views and make them invisible
        let smallScaleTransform = CATransform3DMakeScale(0, 0, 1)
        iconView.layer?.transform = smallScaleTransform
        dotView.layer?.transform = smallScaleTransform
        iconView.layer?.opacity = 0
        dotView.layer?.opacity = 0

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
            storage: &workspaceIconWatcher,
            call: self.iconView.image = workspace.icon
        )
    }

    // MARK: Interaction
    override func mouseEntered(with event: NSEvent) {
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseEntered(workspace.id)
    }

    override func mouseExited(with event: NSEvent) {
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseExited(workspace.id)
    }

    override func mouseDown(with event: NSEvent) {
        guard let workspace else { return }
        interactionDelegate?.workspaceIconMouseClicked(workspace.id)
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

        let hiddenTransform: (CATransform3D, Float) = (CATransform3DMakeScale(0, 0, 1), 0)
        let shownTransform: (CATransform3D, Float) = (CATransform3DIdentity, 1)

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

                iconView.animator().layer?.transform = iconViewTransform.0
                iconView.animator().layer?.opacity = iconViewTransform.1
                iconView.animator().contentTintColor = iconViewColor
                dotView.animator().layer?.transform = dotViewTransform.0
                dotView.animator().layer?.opacity = dotViewTransform.1
            }
        } else {
            iconView.layer?.transform = iconViewTransform.0
            iconView.layer?.opacity = iconViewTransform.1
            iconView.contentTintColor = iconViewColor
            dotView.layer?.transform = dotViewTransform.0
            dotView.layer?.opacity = dotViewTransform.1
        }
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
