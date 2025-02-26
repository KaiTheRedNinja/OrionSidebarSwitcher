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
    /// 4. If the selected workspace has not changed, just resize the currently
    /// focused workspace, or process any pans
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
        let (workspaceToShow, workspaceToPreview, workspacesToRemove, isResettingFromPan) = executeActions(
            currentWorkspaceId: uiState.shownWorkspaceItem,
            actions: actions,
            panHorizontalOffset: panHorizontalOffset,
            workspaces: workspaces
        )

        // --- 5. Update the state ---
        defer {
            uiState = .init(
                shownWorkspaceItem: workspaceToShow,
                horizontalOffset: panHorizontalOffset ?? 0,
                panPreviewWorkspace: workspaceToPreview
            )
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
            // --- 4. If the selected workspace has not changed + pan processing ---
            processPan(
                isResettingFromPan: isResettingFromPan,
                panHorizontalOffset: panHorizontalOffset,
                workspaceToPreview: workspaceToPreview,
                focusedTabViewFrame: focusedTabViewFrame,
                workspaceToShowView: workspaceToShowView
            )

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
            workspacesToRemove: workspacesToRemove,
            animate: panHorizontalOffset == nil
        )

        // ----- c. Add the new workspace to this view, then animate it in -----
        // NOTE: Although this code recieves information to "slide in" this new view, the brief
        // shows the new view appearing in the correct position and simply going from 0 to 1 opacity.
        // therefore, that is what this function does.
        animateInNewView(
            workspaceToShowView: workspaceToShowView,
            newWorkspaceFrame: newWorkspaceFrame,
            focusedTabViewFrame: focusedTabViewFrame,
            animate: panHorizontalOffset == nil
        )

        // ----- d. Delete views that are to be deleted, and are currently not shown -----
        deleteRemovedHiddenViews(
            workspacesToRemove: workspacesToRemove,
            currentWorkspaceId: uiState.shownWorkspaceItem
        )
    }

    private func executeActions(
        currentWorkspaceId: Workspace.ID?,
        actions: [WorkspaceGroupHolderAction],
        panHorizontalOffset: CGFloat?,
        workspaces: [Workspace]
    ) -> (
        workspaceToShow: Workspace.ID?,
        workspaceToPreview: Workspace.ID?,
        workspacesToRemove: Set<Workspace.ID>,
        isResettingFromPan: Bool
    ) {
        var workspaceToShow = currentWorkspaceId
        var workspaceToPreview: Workspace.ID?
        var workspacesToRemove: Set<Workspace.ID> = []
        var isResettingFromPan: Bool = false

        for action in actions {
            switch action {
            case let .workspaceSelected(workspaceId):
                workspaceToShow = workspaceId
            case let .workspaceRemoved(workspaceId):
                workspacesToRemove.insert(workspaceId)
            case let .workspaceAdded(workspace, _):
                let tabListView = WorkspaceTabListView()
                tabListView.workspace = workspace
                tabListView.interactionDelegate = self
                tabListView.setup()
                tabListViews.append(tabListView)
            case .panning:

                // add the views for the workspaces to the left/right of the current workspace
                guard let currentWorkspaceIndex = workspaces.firstIndex(where: { $0.id == currentWorkspaceId }),
                      let panHorizontalOffset
                else { continue }

                // if there is a view on the left, and the preview is towards that direction, mark it
                if currentWorkspaceIndex > 0 && panHorizontalOffset < 0 {
                    workspaceToPreview = workspaces[currentWorkspaceIndex - 1].id
                }
                // same with the one on the right
                if currentWorkspaceIndex < workspaces.count - 1 && panHorizontalOffset > 0 {
                    workspaceToPreview = workspaces[currentWorkspaceIndex + 1].id
                }
            case .panningCancelled:
                isResettingFromPan = true
            }
        }
        return (workspaceToShow, workspaceToPreview, workspacesToRemove, isResettingFromPan)
    }

    private func processPan(
        isResettingFromPan: Bool,
        panHorizontalOffset: CGFloat?,
        workspaceToPreview: Workspace.ID?,
        focusedTabViewFrame: CGRect,
        workspaceToShowView: WorkspaceTabListView
    ) {
        // the currently shown workspace has not changed. Simply update the frame of the workspace to show.
        let horizontalOffset = panHorizontalOffset ?? 0
        // the frame that the currently focused view should take up
        let targetFrame = CGRect(
            x: focusedTabViewFrame.minX - horizontalOffset,
            y: focusedTabViewFrame.minY,
            width: focusedTabViewFrame.width,
            height: focusedTabViewFrame.height
        )
        // the frame that the previewed view should take up. Forbidden from exiting the opposite end.
        let isPreviewingLeft = (panHorizontalOffset ?? uiState.horizontalOffset) < 0
        let widthOffset: CGFloat = focusedTabViewFrame.width*(isPreviewingLeft ? -1 : 1)
        var offsetFrame = CGRect(
            x: focusedTabViewFrame.minX + widthOffset - horizontalOffset,
            y: focusedTabViewFrame.minY,
            width: focusedTabViewFrame.width,
            height: focusedTabViewFrame.height
        )
        // prevent the preview from going too far
        if isPreviewingLeft {
            // is previewing the view to the left - therefore, it is forbidden to reach the right.
            offsetFrame.origin.x = min(0, offsetFrame.origin.x)
        } else {
            // is previewing the view to the right - therefore, it is forbidden to reach the left.
            offsetFrame.origin.x = max(0, offsetFrame.origin.x)
        }

        // if we're ending a pan, we animate. Else, just snap
        guard !isResettingFromPan else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = switchAnimationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                workspaceToShowView.animator().frame = targetFrame

                // move the previewed window towards the direction its meant to go
                tabListViews.first {
                    $0.workspace.id == uiState.panPreviewWorkspace
                }?.animator().frame = offsetFrame
            }

            return
        }

        // if the workspace to preview is different from the currently previewed view, remove it
        if workspaceToPreview != uiState.panPreviewWorkspace {
            tabListViews.first {
                $0.workspace.id == uiState.panPreviewWorkspace
            }?.removeFromSuperview()
        }

        // if theres a workspace to preview, add it to this view and frame it
        if let workspaceToPreview = workspaceToPreview, let previewView = tabListViews.first(where: {
            $0.workspace.id == workspaceToPreview
        }) {
            addSubview(previewView)
            previewView.frame = offsetFrame
        }

        // position the target view
        workspaceToShowView.frame = targetFrame
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
        workspacesToRemove: Set<Workspace.ID>,
        animate: Bool
    ) {
        guard let currentWorkspaceView else { return }

        guard animate else { // just remove it right away
            currentWorkspaceView.removeFromSuperview()
            // if its to be removed, remove it completely
            if workspacesToRemove.contains(currentWorkspaceView.workspace.id) {
                tabListViews.removeAll { $0.workspace.id == currentWorkspaceView.workspace.id }
            }
            return
        }

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
        focusedTabViewFrame: CGRect,
        animate: Bool
    ) {
        // animate in the workspace to show
        // Add the new workspace to this view, out of frame, if it isn't already
        if workspaceToShowView.superview == nil {
            workspaceToShowView.frame = newWorkspaceFrame
            addSubview(workspaceToShowView)
        }

        guard animate else {
            workspaceToShowView.frame = focusedTabViewFrame
            return
        }

        // Animate in the new workspace
        // We delay it a bit so that the animation doesn't conflict with
        // the frame assignment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self else { return }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = self.switchAnimationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                workspaceToShowView.animator().frame = focusedTabViewFrame
            }
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
