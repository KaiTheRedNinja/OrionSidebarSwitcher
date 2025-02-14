//
//  WorkspaceSwitcherView+updateUIElements.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

extension WorkspaceSwitcherView {
    /// A function that wraps ``updateUIElements(actions:)`` by determining which workspaces have been added/removed
    func updateUIElementsForWorkspaceChanges() {
        // determine the current on-screen items, and the new workspace items
        let currentWorkspaceItems = Set(workspaceIconViews.map { $0.workspace.id })
        let newWorkspaceItems = Set(wsGroupManager.workspaceGroup.workspaces.map { $0.id })

        // use set algebra to determine which have been added and which have been removed
        let addedWorkspaceItems = newWorkspaceItems.subtracting(currentWorkspaceItems)
        let removedWorkspaceItems = currentWorkspaceItems.subtracting(newWorkspaceItems)

        // for the added items, determine the indexes that they have been added at
        let addedItemsWithIndex = addedWorkspaceItems.compactMap { (wsId: Workspace.ID) -> (Workspace, Int)? in
            // determine the index and object for the ID
            let addedItem = wsGroupManager.workspaceGroup.workspaces.enumerated().first { (_, workspace) in
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
                     addedItemsWithIndex.map { .workspaceAdded($0.0, insertionIndex: $0.1) }
        )
    }

    /// Called to update the UI given a set of actions. This WILL NOT update the workspace group manager, and should
    /// be called AFTER the workspace group manager has been updated as it assumes that it is
    /// a reliable source of truth
    ///
    /// It does the following:
    /// 1. Determine whether the sidebar is full enough to warrant switching to compact mode
    /// 2. For each workspace that still exists, calculate its new size/position within the sidebar
    /// 3. Execute the actions
    ///     - `workspaceHovered`: Mark that workspace as the one to hover
    ///     - `workspaceUnhovered`: Mark the workspace to hover as nil
    ///     - `workspaceSelected`: Mark that workspace as the one to select
    ///     - `workspaceRemoved`: Mark that workspace as one to remove
    ///     - `workspaceAdded`: Create new empty views
    /// 4. For each workspace view (which currently includes both views to be removed and views to be added),
    ///     - If it is to be removed: Animate its frame changing to 0, then remove it
    ///     - Else: Animate it to the position and rendering style that it is meant to be
    /// 5. If the selected item has changed, animate it shrinking then expanding back to normal size
    /// 6. Update the UI state
    func updateUIElements(actions: [WorkspaceSwitcherAction]) {
        let workspaces = wsGroupManager.workspaceGroup.workspaces

        // --- 1. Determine whether the sidebar is full enough to warrant switching to compact mode ---

        // get the minimum width that the workspaces need if they're all in expanded mode
        let minimumExpandedWidth = CGFloat(workspaces.count) * WorkspaceIconView.minimumExpandedWidth
        // if the minimum width is less than the available width, then the sidebar will switch to compact mode.
        let shouldBeCompact = minimumExpandedWidth < self.frame.width

        // --- 2. For each workspace that still exists, calculate its new size/position within the sidebar ---

        // get the maximum width that all the workspaces can take up if they're all in expanded mode
        let maximumExpandedWidth = CGFloat(workspaces.count) * WorkspaceIconView.maximumExpandedWidth
        // if the maximum width is smaller than the available width, we need to set the starting value a bit further
        // so that the icons are centered. If not, then they can start at the very left of the view.
        let startingX: CGFloat = if maximumExpandedWidth < self.frame.width {
            (self.frame.width - maximumExpandedWidth) / 2
        } else {
            0
        }
        let widthPerIcon: CGFloat = min(
            WorkspaceIconView.maximumExpandedWidth,
            self.frame.width / CGFloat(workspaces.count)
        )

        // determine the width of each icon, given that they all take up the same width
        var workspaceIconPositions: [Workspace.ID: CGRect] = [:]
        var currentX = startingX
        for (index, workspace) in workspaces.enumerated() {
            workspaceIconPositions[workspace.id] = .init(
                x: currentX,
                y: 0,
                width: widthPerIcon,
                height: self.frame.height
            )
            currentX += widthPerIcon
        }

        // --- 3. Execute the actions ---

        var workspaceToHover: Workspace.ID?
        var workspaceToSelect: Workspace.ID = uiState.selectedWorkspaceItem // set to the current workspace
        var workspacesToRemove: Set<Workspace.ID> = []

        for action in actions {
            switch action {
            case let .workspaceHovered(workspaceId):    // Mark that workspace as the one to hover
                workspaceToHover = workspaceId
            case let .workspaceUnhovered(workspaceId):  // Mark the workspace to hover as nil
                if workspaceToHover == workspaceId {
                    workspaceToHover = nil
                }
            case let .workspaceSelected(workspaceId):   // Mark that workspace as the one to select
                workspaceToSelect = workspaceId
            case let .workspaceRemoved(workspaceId):    // Mark that workspace as one to remove
                workspacesToRemove.insert(workspaceId)
            case let .workspaceAdded(workspace, _):  // Create new empty views
                // the workspace must have a position to go to, or else its ignored
                guard let targetFrame = workspaceIconPositions[workspace.id] else { continue }

                let iconView = WorkspaceIconView()
                iconView.workspace = workspace
                iconView.setup()
                iconView.interactionDelegate = self
                iconView.frame = .init(x: targetFrame.midX, y: targetFrame.midY, width: 0, height: 0)
            }
        }

        // --- 4. Update each workspace view ---
        for workspaceIconView in self.workspaceIconViews {
            let workspaceId = workspaceIconView.workspace.id

            // If it is to be removed: Animate its frame changing to 0, then remove it
            if workspacesToRemove.contains(workspaceId) {
                // TODO: animate the view to zero
                workspaceIconView.removeFromSuperview()
                return
            }

            // Else, animate it to the position and rendering style that it is meant to be
            let targetRenderingStyle: WorkspaceIconRenderingStyle = if workspaceToSelect == workspaceId {
                .selected
            } else if workspaceToHover == workspaceId || !shouldBeCompact {
                .unselectedExpanded
            } else {
                .unselectedCompact
            }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                workspaceIconView.animator().frame = workspaceIconPositions[workspaceId]!
                workspaceIconView.layout(renderingStyleChangedTo: targetRenderingStyle)
            }
        }

        // --- 5. If the selected item has changed, animate it shrinking then expanding back to normal size ---
        // TODO: indicator for selected item changing

        // --- 6. Update UI State
        self.uiState = .init(
            isCompact: shouldBeCompact,
            hoveredWorkspaceId: workspaceToHover,
            selectedWorkspaceItem: workspaceToSelect
        )
    }
}
