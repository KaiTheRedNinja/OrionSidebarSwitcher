//
//  WorkspaceGroupHolderView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class WorkspaceGroupHolderView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    private var focusedWorkspaceWatcher: AnyCancellable?
    /// The watcher that detects when the number or order of workspaces change
    /// (eg. workspaces added, removed, rearranged)
    private var workspacesOrderWatcher: AnyCancellable?

    /// A list of the tab list views. The order does not correspond with the order of the workspaces.
    var tabListViews: [WorkspaceTabListView] = []

    /// The state that the UI is currently in. Should only be set by ``updateUIElements(actions:)``.
    var uiState: WorkspaceGroupHolderUIState!

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        // set up the state
        uiState = .init(shownWorkspaceItem: nil)

        // Watch the list of workspaces
        watch(
            attribute: wsGroupManager.workspaceGroup.$workspaces,
            storage: &workspacesOrderWatcher
        ) { workspaces in
            self.updateUIElementsForWorkspaceChanges(workspaces: workspaces)
        }

        // Watch the currently focused workspace
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceWatcher
        ) { focusedWorkspaceId in
            self.updateUIElements(
                actions: [
                    .workspaceSelected(focusedWorkspaceId)
                ],
                workspaces: self.wsGroupManager.workspaceGroup.workspaces
            )
        }
    }

    /// A function that wraps ``updateUIElements(actions:)`` by determining which workspaces have been added/removed
    func updateUIElementsForWorkspaceChanges(workspaces: [Workspace]) {
        // determine the current on-screen items, and the new workspace items
        let currentWorkspaceItems = Set(tabListViews.map { $0.workspace.id })
        let newWorkspaceItems = Set(workspaces.map { $0.id })

        // use set algebra to determine which have been added and which have been removed
        let addedWorkspaceItems = newWorkspaceItems.subtracting(currentWorkspaceItems)
        let removedWorkspaceItems = currentWorkspaceItems.subtracting(newWorkspaceItems)

        // for the added items, determine the indexes that they have been added at
        let addedItemsWithIndex = addedWorkspaceItems.compactMap { (wsId: Workspace.ID) -> (Workspace, Int)? in
            // determine the index and object for the ID
            let addedItem = workspaces.enumerated().first { (_, workspace) in
                workspace.id == wsId
            }
            if let addedItem {
                return (addedItem.element, addedItem.offset)
            } else {
                return nil
            }
        }

        // updatee the UI elements with these removed and added items
        updateUIElements(
            actions: removedWorkspaceItems.map { .workspaceRemoved($0) } +
            addedItemsWithIndex.map { .workspaceAdded($0.0, insertionIndex: $0.1) },
            workspaces: workspaces
        )
    }

    override func layout() {
        guard let wsGroupManager else { return }
        updateUIElements(actions: [], workspaces: wsGroupManager.workspaceGroup.workspaces)
    }

    /// Called to update the UI given a set of actions. This WILL NOT update the workspace group manager, and should
    /// be called AFTER the workspace group manager has been updated as it assumes that it is
    /// a reliable source of truth
    ///
    /// It does the following:
    /// 1. Determine the frame that the focused tab view should take up
    /// 2. Execute the actions
    ///     - `workspaceSelected`: Mark that view as the new current view
    ///     - `workspaceRemoved`: Delete the view for it
    ///     - `workspaceAdded`: Create a view for it
    /// 3. If the selected workspace has changed:
    ///     a. Determine which direction the new workspace is coming from
    ///     b. Add the new workspace to this view, out of frame
    ///     c. Animate out the old workspace, and animate in the new workspace
    ///     d. After the animation, remove the old workspace from this view
    /// 4. Else, just resize the currently focused workspace
    /// 5. Update the UI state
    func updateUIElements( // swiftlint:disable:this function_body_length cyclomatic_complexity
        actions: [WorkspaceGroupHolderAction],
        workspaces: [Workspace]
    ) {
        // --- 1. Determine the frame that the focused tab view should take up ---
        let focusedTabViewFrame = self.bounds

        // --- 2. Execute the actions ---
        var workspaceToShow = uiState.shownWorkspaceItem
        var workspacesToRemove: Set<Workspace.ID> = []
        for action in actions {
            switch action {
            case let .workspaceSelected(workspaceId):
                workspaceToShow = workspaceId
            case let .workspaceRemoved(workspaceId):
                workspacesToRemove.insert(workspaceId)
            case let .workspaceAdded(workspace, _):
                let tabListView = WorkspaceTabListView()
                tabListView.workspace = workspace
                tabListView.setup()
                tabListViews.append(tabListView)
            }
        }

        // Update the state
        defer {
            uiState = .init(shownWorkspaceItem: workspaceToShow)
        }

        // get the index and view of the currently shown workspace. This will be nil if
        // there is no currently shown workspace.
        let currentWorkspaceIndex = workspaces.firstIndex { $0.id == uiState.shownWorkspaceItem }
        let currentWorkspaceView = tabListViews.first { $0.workspace.id == uiState.shownWorkspaceItem }

        // get the position of the workspace to show. This MUST exist.
        guard
            let workspaceToShowIndex = workspaces.firstIndex(where: { $0.id == workspaceToShow }),
            let workspaceToShowView = tabListViews.first(where: { $0.workspace.id == workspaceToShow })
        else { return }

        // --- 3. If the selected workspace has changed ---
        guard workspaceToShowIndex != currentWorkspaceIndex else {
            // the currently shown workspace has not changed. Simply update the frame of the workspace to show.
            workspaceToShowView.frame = focusedTabViewFrame
            return
        }

        // Determine which direction the new workspace is coming from

        // The horizontal offset of the incoming view, in terms of the width of the frame.
        // This has three possible values:
        // 1: The frame is offset to the right by its width, making it just outside the right of view
        // 0: The frame is not offset
        // -1: The frame is offset to the left by its width, making it just outside the left of view
        let horizontalOffset: CGFloat = if let currentWorkspaceIndex {
            if currentWorkspaceIndex < workspaceToShowIndex {
                1 // workspaceToShow is "to the right", so it should appear from the right
            } else {
                -1 // workspaceToShow is "to the left", so it should appear from the left
            }
        } else {
            0 // there is no current workspace, so the workspace just shows up in the middle
        }

        // The view that the incoming view should go to before animating to the target frame
        let newWorkspaceFrame = CGRect(
            x: focusedTabViewFrame.minX + horizontalOffset*focusedTabViewFrame.width,
            y: 0,
            width: focusedTabViewFrame.width,
            height: focusedTabViewFrame.height
        )
        // The view that the outgoing view should animate to from the target frame. This is
        // the opposite direction from the newWorkspaceFrame.
        let oldWorkspaceFrame = CGRect(
            x: focusedTabViewFrame.minX - horizontalOffset*focusedTabViewFrame.width,
            y: 0,
            width: focusedTabViewFrame.width,
            height: focusedTabViewFrame.height
        )

        // animate out the currently shown view
        if let currentWorkspaceView {
            // Animate out the old workspace
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                currentWorkspaceView.animator().frame = oldWorkspaceFrame
            }
            // After the animation, remove the old workspace from this view
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                currentWorkspaceView.removeFromSuperview()

                // if its to be removed, remove it completely
                if workspacesToRemove.contains(currentWorkspaceView.workspace.id) {
                    self?.tabListViews.removeAll { $0.workspace.id == currentWorkspaceView.workspace.id }
                }
            }
        }

        // animate in the workspace to show
        // Add the new workspace to this view, out of frame
        workspaceToShowView.frame = newWorkspaceFrame
        addSubview(workspaceToShowView)

        // Animate in the new workspace
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            workspaceToShowView.animator().frame = focusedTabViewFrame
        }

        // remove all the views that are to be removed, with exception for the currently shown workspace
        for workspaceToRemove in workspacesToRemove where workspaceToRemove != uiState.shownWorkspaceItem {
            tabListViews.removeAll { $0.workspace.id == workspaceToRemove }
        }
    }
}

/// An object that tracks the state of the workspace group holder's UI
struct WorkspaceGroupHolderUIState: Equatable {
    /// The ID of the currently shown workspace item
    ///
    /// Can be nil if the view has not rendered the selected view yet
    var shownWorkspaceItem: Workspace.ID?
}

/// An action triggerd by the workspace group holder's UI or the backend
enum WorkspaceGroupHolderAction {
    /// The user has clicked a given workspace icon view
    case workspaceSelected(Workspace.ID)
    /// The given workspace has been removed
    case workspaceRemoved(Workspace.ID)
    /// A workspace has been added at the given insertion point
    case workspaceAdded(Workspace, insertionIndex: Int)
}
