//
//  WorkspaceGroupManager.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Foundation
import Combine

/// A manager in charge of managing a `WorkspaceGroup` and its constituent `Workspace`s.
///
/// This object provides a consistent API for getting and mutating attributes of the
/// `WorkspaceGroup`, `Workspace`s, and `TabItem`s.
class WorkspaceGroupManager {
    /// The workspace group that this manager manages.
    ///
    /// Although the caller is allowed to directly modify this object, callers are highly recommended
    /// to use the API surface provided by the `WorkspaceGroupManager` instead
    var workspaceGroup: WorkspaceGroup

    /// Creates a workspace manager from a workspace group
    init(workspaceGroup: WorkspaceGroup) {
        self.workspaceGroup = workspaceGroup
    }

    // MARK: Getters

    /// Retrieves the currently focused workspace
    func currentWorkspace() -> Workspace {
        // Determine the workspace, for which its ID matches the focused workspace ID
        guard let focusedWorkspace = workspaceGroup.workspaces.first(where: {
                  $0.id == workspaceGroup.focusedWorkspaceID
              })
        else {
            // It is considered invalid state to have no focused workspace
            fatalError("No focused workspace found")
        }

        return focusedWorkspace
    }

    /// Retrieves the currently selected tab of the currently focused workspace
    func currentWorkspaceTab() -> TabItem {
        let focusedWorkspace = currentWorkspace()

        // Determine the tab, for which its ID matches the selected tab ID
        guard let selectedTab = focusedWorkspace.allTabs.first(where: {
                  $0.id == focusedWorkspace.selectedTabId
              })
        else {
            // It is considered invalid state to have no selected tab
            fatalError("No focused workspace found, or no selected tab found")
        }

        return selectedTab
    }

    // MARK: Setters

    /// Focuses the given workspace
    func focus(workspaceWithId workspaceId: Workspace.ID) {
        // update the state
        workspaceGroup.focusedWorkspaceID = workspaceId
    }

    /// Deletes the given workspace
    func delete(workspaceWithId workspaceId: Workspace.ID) {
        // refuse to delete if this is the only workspace left, or if it doesn't exist
        guard workspaceGroup.workspaces.count > 1,
              let workspaceIndex = workspaceGroup.workspaces.firstIndex(where: { $0.id == workspaceId })
        else { return }

        // if this workspace is the selected one, select the next one
        if workspaceGroup.focusedWorkspaceID == workspaceId {
            let targetIndex = (workspaceIndex+1)%workspaceGroup.workspaces.count
            focus(workspaceWithId: workspaceGroup.workspaces[targetIndex].id)
        }

        workspaceGroup.workspaces.remove(at: workspaceIndex)
    }

    /// Adds a new blank workspace
    func addWorkspace(workspace: Workspace = .blankWorkspace(), focusAfterCreating: Bool = true) {
        workspaceGroup.workspaces.append(workspace)
        if focusAfterCreating {
            focus(workspaceWithId: workspace.id)
        }
    }
}
