//
//  WorkspaceGroupHolderView+updateUIElements.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 16/2/25.
//

import Cocoa

extension WorkspaceGroupHolderView {
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
    /// 3. Determine if the selected workspace has changed
    /// 4. If the selected workspace has not changed, just resize the currently focused workspace
    /// 5. Else (ie, the selected workspace HAS changed), animate it
    ///     a. Determine which direction the new workspace is coming from
    ///     b. Animate out the old workspace, then remove it from this view
    ///     c. Add the new workspace to this view, then animate it in
    ///     d. Delete views that are to be deleted, and are currently not shown
    /// 6. Update the UI state
    func updateUIElements(
        actions: [WorkspaceGroupHolderAction],
        workspaces: [Workspace]
    ) {
        // --- 1. Determine the frame that the focused tab view should take up ---
        let focusedTabViewFrame = self.bounds

        // --- 2. Execute the actions ---
        let (workspaceToShow, workspacesToRemove) = executeActions(
            currentWorkspaceId: uiState.shownWorkspaceItem,
            actions: actions
        )

        // --- 5. Update the state ---
        defer {
            uiState = .init(shownWorkspaceItem: workspaceToShow)
        }

        // --- 3. Determine if the selected workspace has changed ---

        // get the index and view of the currently shown workspace. This will be nil if
        // there is no currently shown workspace.
        let currentWorkspaceIndex = workspaces.firstIndex { $0.id == uiState.shownWorkspaceItem }
        let currentWorkspaceView = tabListViews.first { $0.workspace.id == uiState.shownWorkspaceItem }

        // get the position of the workspace to show. This MUST exist.
        guard let workspaceToShowIndex = workspaces.firstIndex(where: { $0.id == workspaceToShow }),
              let workspaceToShowView = tabListViews.first(where: { $0.workspace.id == workspaceToShow })
        else { return }

        guard workspaceToShowIndex != currentWorkspaceIndex else {
            // --- 4. If the selected workspace has changed ---

            // the currently shown workspace has not changed. Simply update the frame of the workspace to show.
            workspaceToShowView.frame = focusedTabViewFrame
            return
        }

        // --- 5. The selected workspace HAS changed, animate it ---

        // ----- a. Determine which direction the new workspace is coming from -----

        let (newWorkspaceFrame, oldWorkspaceFrame) = workspaceFrames(
            currentWorkspaceIndex: currentWorkspaceIndex,
            workspaceToShowIndex: workspaceToShowIndex,
            focusedTabViewFrame: focusedTabViewFrame
        )

        // ----- b. Animate out the old workspace, then remove it from this view -----
        animateOutOldView(
            currentWorkspaceView: currentWorkspaceView,
            oldWorkspaceFrame: oldWorkspaceFrame,
            workspacesToRemove: workspacesToRemove
        )

        // ----- c. Add the new workspace to this view, then animate it in -----
        // NOTE: Although this code recieves information to "slide in" this new view, the brief
        // shows the new view appearing in the correct position and simply going from 0 to 1 opacity.
        // therefore, that is what this function does.
        animateInNewView(
            workspaceToShowView: workspaceToShowView,
            newWorkspaceFrame: newWorkspaceFrame,
            focusedTabViewFrame: focusedTabViewFrame
        )

        // ----- d. Delete views that are to be deleted, and are currently not shown -----
        deleteRemovedHiddenViews(
            workspacesToRemove: workspacesToRemove,
            currentWorkspaceId: uiState.shownWorkspaceItem
        )
    }

    private func executeActions(
        currentWorkspaceId: Workspace.ID?,
        actions: [WorkspaceGroupHolderAction]
    ) -> (
        workspaceToShow: Workspace.ID?,
        workspacesToRemove: Set<Workspace.ID>
    ) {
        var workspaceToShow = currentWorkspaceId
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
        return (workspaceToShow, workspacesToRemove)
    }

    private func workspaceFrames(
        currentWorkspaceIndex: Int?,
        workspaceToShowIndex: Int,
        focusedTabViewFrame: CGRect
    ) -> (
        newWorkspaceFrame: CGRect,
        oldWorkspaceFrame: CGRect
    ) {
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

        return (newWorkspaceFrame, oldWorkspaceFrame)
    }

    private func animateOutOldView(
        currentWorkspaceView: WorkspaceTabListView?,
        oldWorkspaceFrame: CGRect,
        workspacesToRemove: Set<Workspace.ID>
    ) {
        guard let currentWorkspaceView else { return }

        // Animate out the old workspace
        NSAnimationContext.runAnimationGroup { context in
            context.duration = switchAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            currentWorkspaceView.animator().frame = oldWorkspaceFrame
        }
        // After the animation, remove the old workspace from this view
        DispatchQueue.main.asyncAfter(deadline: .now() + switchAnimationDuration) { [weak self] in
            currentWorkspaceView.removeFromSuperview()

            // if its to be removed, remove it completely
            if workspacesToRemove.contains(currentWorkspaceView.workspace.id) {
                self?.tabListViews.removeAll { $0.workspace.id == currentWorkspaceView.workspace.id }
            }
        }
    }

    private func animateInNewView(
        workspaceToShowView: WorkspaceTabListView,
        newWorkspaceFrame: CGRect,
        focusedTabViewFrame: CGRect
    ) {
        // animate in the workspace to show
        // Add the new workspace to this view, out of frame
        workspaceToShowView.frame = focusedTabViewFrame
        workspaceToShowView.alphaValue = 0
        addSubview(workspaceToShowView)

        // Animate in the new workspace
        NSAnimationContext.runAnimationGroup { context in
            context.duration = switchAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            workspaceToShowView.animator().alphaValue = 1
        }
    }

    private func deleteRemovedHiddenViews(
        workspacesToRemove: Set<Workspace.ID>,
        currentWorkspaceId: Workspace.ID?
    ) {
        // remove all the views that are to be removed, with exception for the currently shown workspace
        for workspaceToRemove in workspacesToRemove where workspaceToRemove != currentWorkspaceId {
            tabListViews.removeAll { $0.workspace.id == workspaceToRemove }
        }
    }
}
