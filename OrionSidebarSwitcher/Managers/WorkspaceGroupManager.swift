//
//  WorkspaceGroupManager.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Foundation

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

    /// Focuses the given workspace
    func focus(workspaceWithId workspaceId: Workspace.ID) {
        workspaceGroup.focusedWorkspaceID = workspaceId
    }
}
