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
    /// 3. For each workspace view (which currently includes both views to be removed and views to be added),
    ///     - If it is to be removed: Animate its frame changing to 0, then remove it
    ///     - Else: Animate it to the position and rendering state that it is meant to be
    /// 4. If the selected item has changed, animate it shrinking then expanding back to normal size
    func updateUIElements(actions: [WorkspaceSwitcherAction]) {
    }
}
