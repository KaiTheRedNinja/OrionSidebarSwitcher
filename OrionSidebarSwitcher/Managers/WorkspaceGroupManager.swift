//
//  WorkspaceGroupManager.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Foundation

/// A manager in charge of managing a `WorkspaceGroup` and its constituent `Workspace`s.
///
/// This object provides a consistent API for mutating attributes of the `WorkspaceGroup`, `Workspace`s, and `TabItem`s.
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
}
