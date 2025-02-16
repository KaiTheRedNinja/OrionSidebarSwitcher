//
//  WorkspaceSwitcherView+updateUIElements.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

extension WorkspaceSwitcherView {
    /// A function that wraps ``updateUIElements(actions:)`` by determining which workspaces have been added/removed
    func updateUIElementsForWorkspaceChanges(workspaces: [Workspace]) {
        // determine the current on-screen items, and the new workspace items
        let currentWorkspaceItems = Set(workspaceIconViews.map { $0.workspace.id })
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
    ///     - The "click" icon's animation is settled by the icon view itself
    /// 5. Update the UI state
    func updateUIElements(actions: [WorkspaceSwitcherAction], workspaces: [Workspace]) {
        // --- 1. Determine whether the sidebar is full enough to warrant switching to compact mode ---
        let availableWidth = self.frame.width - 30 - 5 // make space for the + button and leading padding
        let shouldBeCompact = shouldBeCompactGiven(
            workspaceCount: workspaces.count,
            minimumExpandedWidth: WorkspaceIconView.minimumExpandedWidth,
            availableWidth: availableWidth
        )

        // --- 2. For each workspace that still exists, calculate its new size/position within the sidebar ---
        let (workspaceIconPositions, totalWidth) = workspaceIconPositionsGiven(
            workspaces: workspaces,
            minimumCompactWidth: WorkspaceIconView.minimumCompactWidth,
            maximumExpandedWidth: WorkspaceIconView.maximumExpandedWidth,
            availableWidth: availableWidth
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

        // update the scroll view
        updateOtherViews(totalWidth: totalWidth)

        // --- 5. Update UI State
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
        minimumCompactWidth: CGFloat,
        maximumExpandedWidth: CGFloat,
        availableWidth: CGFloat
    ) -> (
        workspaceIconPositions: [Workspace.ID: CGRect],
        totalWidth: CGFloat
    ) {
        // get the maximum width that all the workspaces can take up if they're all in expanded mode
        let maximumTotalWidth = CGFloat(workspaces.count) * maximumExpandedWidth
        // if the maximum width is smaller than the available width, we need to set the starting value a bit further
        // so that the icons are centered. If not, then they can start at the very left of the view.
        let startingX: CGFloat = if maximumTotalWidth < availableWidth {
            (availableWidth - maximumTotalWidth) / 2
        } else {
            0
        }

        let widthPerIcon: CGFloat = max(
            minimumCompactWidth,
            min(
                availableWidth / CGFloat(workspaces.count),
                maximumExpandedWidth
            )
        )

        // determine the frames of each icon, given that they all take up the same width
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

        // the total width is the sum of the widths of each icon, or the available
        // width, whichever is larger
        let totalWidth = max(availableWidth, widthPerIcon * CGFloat(workspaces.count))

        return (workspaceIconPositions, totalWidth)
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
                iconView.frame = .init(x: targetFrame.minX, y: 0, width: 0, height: frame.height)
                self.workspaceIconViews.append(iconView)
                self.scrollView.documentView?.addSubview(iconView)
            }
        }

        return (workspaceToHover, workspaceToSelect, workspacesToRemove)
    }

    private func updateWorkspaceViews( // swiftlint:disable:this function_parameter_count
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
            guard !workspacesToRemove.contains(workspaceId) else {
                // TODO: animate the view to zero
                workspaceIconView.removeFromSuperview()
                if let index = workspaceIconViews.firstIndex(of: workspaceIconView) {
                    workspaceIconViews.remove(at: index)
                }
                continue
            }

            // If it doesn't have a frame: It is in the process of being removed, ignore it
            guard let frame = workspaceIconPositions[workspaceId] else { continue }

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
                    workspaceIconView.animator().frame = frame
                }
            } else {
                workspaceIconView.frame = frame
            }

            workspaceIconView.layout(renderingStyleChangedTo: targetRenderingStyle)
        }
    }

    private func updateOtherViews(
        totalWidth: CGFloat
    ) {
        scrollView.documentView?.frame = .init(
            x: 0,
            y: 0,
            width: totalWidth,
            height: self.frame.height
        )
        scrollView.frame = .init(
            x: 5,
            y: 0,
            width: self.frame.width - 30,
            height: self.frame.height
        )
        // update the plus icon
        addWorkspaceIconView.frame = .init(
            x: self.frame.width - 30,
            y: 0,
            width: 30,
            height: self.frame.height
        )
    }
}
