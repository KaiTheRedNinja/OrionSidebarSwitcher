//
//  WorkspaceGroup.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Foundation

/// An object which holds the data associated with a group of workspaces
class WorkspaceGroup: Identifiable, ObservableObject {
    /// A unique identifier for the workspace group
    let id: UUID

    /// The workspaces within the group
    @Published var workspaces: [Workspace]
    /// The ID of the currently focused workspace
    @Published var focusedWorkspaceID: Workspace.ID

    init(
        id: UUID = .init(),
        workspaces: [Workspace],
        focusedWorkspaceID: Workspace.ID
    ) {
        self.id = id
        self.workspaces = workspaces
        self.focusedWorkspaceID = focusedWorkspaceID
    }

    /// A factory method which creates a workspace group with a single "Blank Workspace".
    /// Calling this function repeatedly will produce `Workspace`s with identical details, but with
    /// different `id`s and tab `id`s. The `focusedWorkspaceID` is guarenteed to be the same
    /// as the sole `workspace`'s.
    static func blankWorkspaceGroup() -> WorkspaceGroup {
        let blankWorkspace = Workspace.blankWorkspace()

        return .init(
            workspaces: [blankWorkspace],
            focusedWorkspaceID: blankWorkspace.id
        )
    }
}
