//
//  WorkspaceTabListView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa
import Combine

/// A view that contains the contents of a workspace tab
class WorkspaceTabListView: NSView {
    /// The workspace that this view lists tabs for. This is a strong reference so that we can still access the ID
    /// after the workspace is removed from the manager.
    var workspace: Workspace!
    /// The interaction delegate
    var interactionDelegate: WorkspaceTabListInteractionDelegate?

    /// The watcher that watches for when the selected tab changes
    var selectedTabWatcher: AnyCancellable?

    /// The text label for the workspace's title
    var titleView: NSText!
    /// The view containing the pinned tabs
    var pinnedTabsView: WorkspacePinnedTabsView!
    /// The view containing the normal tabs
    var normalTabsView: WorkspaceNormalTabsView!

    /// How much horizontal padding the contents have between the edge of the view
    var horizontalPadding: CGFloat = 10
    /// How much vertical spacing the contents have between each other
    var verticalSpacing: CGFloat = 6

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        self.titleView = NSText()
        titleView.string = workspace.name
        titleView.textColor = .gray
        titleView.backgroundColor = .clear
        titleView.isEditable = true
        titleView.font = .boldSystemFont(ofSize: 12)
        titleView.isSelectable = true
        titleView.delegate = self
        addSubview(titleView)

        self.pinnedTabsView = WorkspacePinnedTabsView()
        pinnedTabsView.pinnedTabs = workspace.pinnedTabs
        pinnedTabsView.interactionDelegate = self
        pinnedTabsView.setup()
        addSubview(pinnedTabsView)

        self.normalTabsView = WorkspaceNormalTabsView()
        normalTabsView.normalTabs = workspace.regularTabs
        normalTabsView.interactionDelegate = self
        normalTabsView.setup()
        addSubview(normalTabsView)

        watch(
            attribute: workspace.$selectedTabId,
            storage: &selectedTabWatcher
        ) { [weak self] selectedTab in
            guard let self else { return }
            pinnedTabsView.selectedTab = selectedTab
            normalTabsView.selectedTab = selectedTab
            pinnedTabsView.updateUIElements()
            normalTabsView.updateUIElements()
        }

        // unfocus the text view
        window?.makeFirstResponder(nil)
    }

    override var isFlipped: Bool { true }

    override func layout() {
        // How wide the content is, accounting for padding
        let contentWidth = self.bounds.width - horizontalPadding*2

        // title view at the top. We do manual adjustment so that
        // the view appears vertically centered
        let titleViewTextHeight: CGFloat = 15
        let titleViewHeight: CGFloat = 18
        titleView.frame = .init(
            x: horizontalPadding,
            y: (titleViewHeight-titleViewTextHeight)/2 + verticalSpacing,
            width: contentWidth,
            height: titleViewTextHeight
        )

        // pinned tabs view right below
        let pinnedTabsViewHeight = pinnedTabsView.idealHeight(forWidth: contentWidth)
        let pinnedTabsTargetFrame = CGRect(
            x: horizontalPadding,
            y: titleView.frame.maxY + verticalSpacing,
            width: contentWidth,
            height: pinnedTabsViewHeight
        )
        // if the height changed, thats likely because the number of rows changed. Therefore, we animate.
        let animateFrameChange = (
            pinnedTabsView.frame.height != pinnedTabsTargetFrame.height &&  // height changed
            pinnedTabsView.frame.height != 0                                // height wasn't 0
        )
        pinnedTabsView.frame.size.width = pinnedTabsTargetFrame.width
        if animateFrameChange {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pinnedTabsView.animator().frame = pinnedTabsTargetFrame
            }
        } else {
            pinnedTabsView.frame = pinnedTabsTargetFrame
        }
        pinnedTabsView.layout()

        // normal tabs view all the way down
        let normalTabsTargetFrame = CGRect(
            x: 0,
            y: pinnedTabsView.frame.maxY + verticalSpacing,
            width: self.bounds.width,
            height: self.bounds.height - pinnedTabsView.frame.maxY - verticalSpacing
        )
        normalTabsView.frame.size.width = normalTabsTargetFrame.width
        if animateFrameChange {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                normalTabsView.animator().frame = normalTabsTargetFrame
            }
        } else {
            normalTabsView.frame = normalTabsTargetFrame
        }
    }
}

extension WorkspaceTabListView: TabInteractionDelegate {
    func tabWasPressed(tabId: TabItem.ID) {
        interactionDelegate?.tabWasPressed(tabId: tabId, inWorkspaceId: workspace.id)
    }
}

extension WorkspaceTabListView: NSTextDelegate {
    func textDidChange(_ notification: Notification) {
        if titleView.string.contains("\n") {
            window?.makeFirstResponder(nil)
        }
        workspace.name = titleView.string.replacingOccurrences(of: "\n", with: "")
    }
}

// Note: This interaction delegate is located within this file because its used
// in almost every tab-related file and the WorkspaceTabListView is the logical
// root of all of them
/// A delegate which is informed of interactions within the tab
protocol TabInteractionDelegate: AnyObject {
    /// Informs the delegate that the given tab has been selected
    func tabWasPressed(tabId: TabItem.ID)
}

/// A delegate which is informed of interactions within the tab list
protocol WorkspaceTabListInteractionDelegate: AnyObject {
    /// Informs the delegate that the given tab in the given workspace has been selected
    func tabWasPressed(tabId: TabItem.ID, inWorkspaceId workspaceId: Workspace.ID)
}
