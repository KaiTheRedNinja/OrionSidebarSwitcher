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
                     addedItemsWithIndex.map { .workspaceAdded($0.0, insertionIndex: $0.1) },
            workspaces: wsGroupManager.workspaceGroup.workspaces
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
    func updateUIElements(actions: [WorkspaceSwitcherAction], workspaces: [Workspace]) {
        // --- 1. Determine whether the sidebar is full enough to warrant switching to compact mode ---
        let shouldBeCompact = shouldBeCompactGiven(
            workspaceCount: workspaces.count,
            minimumExpandedWidth: WorkspaceIconView.minimumExpandedWidth,
            availableWidth: self.frame.width
        )

        // --- 2. For each workspace that still exists, calculate its new size/position within the sidebar ---
        let workspaceIconPositions = workspaceIconPositionsGiven(
            workspaces: workspaces,
            maximumExpandedWidth: WorkspaceIconView.maximumExpandedWidth
        )

        // --- 3. Execute the actions ---
        let (workspaceToHover, workspaceToSelect, workspacesToRemove) = executeActions(
            workspaceIconPositions: workspaceIconPositions,
            hoveredWorkspaceId: uiState.hoveredWorkspaceId,
            selectedWorkspaceItem: uiState.selectedWorkspaceItem,
            actions: actions
        )

        // --- 4. Update each workspace view ---
        let shouldAnimate = actions.contains { // we animate position when workspaces have changed
            switch $0 {
            case .workspaceAdded, .workspaceRemoved: true
            default: false
            }
        }
        updateWorkspaceViews(
            workspacesToRemove: workspacesToRemove,
            workspaceToSelect: workspaceToSelect,
            workspaceToHover: workspaceToHover,
            shouldBeCompact: shouldBeCompact,
            animateMovement: shouldAnimate,
            workspaceIconPositions: workspaceIconPositions
        )

        // --- 5. If the selected item has changed, animate it shrinking then expanding back to normal size ---
        // TODO: indicator for selected item changing

        // --- 6. Update UI State
        self.uiState = .init(
            isCompact: shouldBeCompact,
            hoveredWorkspaceId: workspaceToHover,
            selectedWorkspaceItem: workspaceToSelect
        )
    }

    private func shouldBeCompactGiven(
        workspaceCount: Int,
        minimumExpandedWidth: CGFloat,
        availableWidth: CGFloat
    ) -> Bool {
        // get the minimum width that the workspaces need if they're all in expanded mode
        let minimumTotalWidth = CGFloat(workspaceCount) * minimumExpandedWidth
        // if the minimum width is more than the available width, then the sidebar will switch to compact mode.
        return minimumTotalWidth > availableWidth
    }

    private func workspaceIconPositionsGiven(
        workspaces: [Workspace],
        maximumExpandedWidth: CGFloat
    ) -> [Workspace.ID: CGRect] {
        // get the maximum width that all the workspaces can take up if they're all in expanded mode
        let maximumTotalWidth = CGFloat(workspaces.count) * maximumExpandedWidth
        // if the maximum width is smaller than the available width, we need to set the starting value a bit further
        // so that the icons are centered. If not, then they can start at the very left of the view.
        let startingX: CGFloat = if maximumTotalWidth < self.frame.width {
            (self.frame.width - maximumTotalWidth) / 2
        } else {
            0
        }
        let widthPerIcon: CGFloat = min(
            maximumExpandedWidth,
            self.frame.width / CGFloat(workspaces.count)
        )

        // determine the width of each icon, given that they all take up the same width
        var workspaceIconPositions: [Workspace.ID: CGRect] = [:]
        var currentX = startingX
        for workspace in workspaces {
            workspaceIconPositions[workspace.id] = .init(
                x: currentX,
                y: 0,
                width: widthPerIcon,
                height: self.frame.height
            )
            currentX += widthPerIcon
        }

        return workspaceIconPositions
    }

    private func executeActions(
        workspaceIconPositions: [Workspace.ID: CGRect],
        hoveredWorkspaceId: Workspace.ID?,
        selectedWorkspaceItem: Workspace.ID,
        actions: [WorkspaceSwitcherAction]
    ) -> (
        workspaceToHover: Workspace.ID?,
        workspaceToSelect: Workspace.ID,
        workspacesToRemove: Set<Workspace.ID>
    ) {
        var workspaceToHover: Workspace.ID? = hoveredWorkspaceId
        var workspaceToSelect: Workspace.ID = selectedWorkspaceItem
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
                self.workspaceIconViews.append(iconView)
                self.addSubview(iconView)
            }
        }

        return (workspaceToHover, workspaceToSelect, workspacesToRemove)
    }

    fileprivate func updateWorkspaceViews( // swiftlint:disable:this function_parameter_count
        workspacesToRemove: Set<Workspace.ID>,
        workspaceToSelect: Workspace.ID,
        workspaceToHover: Workspace.ID?,
        shouldBeCompact: Bool,
        animateMovement: Bool,
        workspaceIconPositions: [Workspace.ID: CGRect]
    ) {
        for workspaceIconView in self.workspaceIconViews {
            let workspaceId = workspaceIconView.workspace.id

            // If it is to be removed: Animate its frame changing to 0, then remove it
            if workspacesToRemove.contains(workspaceId) {
                // TODO: animate the view to zero
                workspaceIconView.removeFromSuperview()
                return
            }

            // Determine how to render it
            let targetRenderingStyle: WorkspaceIconRenderingStyle = if workspaceToSelect == workspaceId {
                .selected // the item is selected
            } else if workspaceToHover == workspaceId || !shouldBeCompact {
                .unselectedExpanded // the item is hovered, or the sidebar is expanded
            } else {
                .unselectedCompact  // the item is not hovered and the sidebar is compacted
            }

            // animate if needed
            if animateMovement {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    workspaceIconView.animator().frame = workspaceIconPositions[workspaceId]!
                }
            } else {
                workspaceIconView.frame = workspaceIconPositions[workspaceId]!
            }

            workspaceIconView.layout(renderingStyleChangedTo: targetRenderingStyle)
        }
    }
}
