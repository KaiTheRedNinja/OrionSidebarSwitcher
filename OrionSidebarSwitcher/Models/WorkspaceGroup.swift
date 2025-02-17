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

    /// The workspaces within the group. This must have at least ONE workspace,
    /// having zero workspaces is considered invalid state.
    @Published var workspaces: [Workspace]
    /// The ID of the currently focused workspace. This must correspond with EXACTLY ONE
    /// workspace in ``workspaces``, corresponding with zero or multiple is considered
    /// invalid state
    @Published var focusedWorkspaceID: Workspace.ID

    /// Creates a workspace group with a list of workspaces and the workspace to focus. If not provided, it defaults
    /// to the first workspace.
    init(
        id: UUID = .init(),
        workspaces: [Workspace],
        focusedWorkspaceID: Workspace.ID? = nil
    ) {
        assert(!workspaces.isEmpty, "Cannot create a workspace group with zero workspaces")
        self.id = id
        self.workspaces = workspaces
        self.focusedWorkspaceID = focusedWorkspaceID ?? workspaces[0].id
    }

    /// A factory method which creates a workspace group with a given number of "Blank Workspaces".
    /// Calling this function repeatedly will produce `Workspace`s with identical details, but with
    /// different `id`s and tab `id`s. The `focusedWorkspaceID` is guarenteed to be the same
    /// as the sole `workspace`'s.
    static func blankWorkspaceGroup(workspaceCount: Int = 1) -> WorkspaceGroup {
        assert(workspaceCount >= 1, "Cannot create a workspace group with zero workspaces")
        let blankWorkspaces = (0..<workspaceCount).map { _ in Workspace.blankWorkspace() }

        return .init(
            workspaces: blankWorkspaces,
            focusedWorkspaceID: blankWorkspaces[0].id
        )
    }

    /// A factory method which creates a workspace with sample data. Follows the same repeat rules as above.
    static func sampleWorkspaceGroup() -> WorkspaceGroup {
        WorkspaceGroup(
            workspaces: [
                .init(
                    name: "MacBook",
                    icon: .init(systemSymbolName: "macbook", accessibilityDescription: "Tab Icon")!,
                    pinnedTabs: [
                        .init(name: "Tim Cook", icon: TabItem.defaultIcon),
                        .init(name: "Hair Force One", icon: TabItem.defaultIcon),
                        .init(name: "Jony Ive", icon: TabItem.defaultIcon),
                        .init(name: "Steve Jobs", icon: TabItem.defaultIcon),
                        .init(name: "Woz", icon: TabItem.defaultIcon)
                    ],
                    regularTabs: [
                        .init(name: "Reviews", icon: TabItem.defaultIcon),
                        .init(name: "Comparisons", icon: TabItem.defaultIcon)
                    ]
                ),
                .blankWorkspace(),
                .init(
                    name: "Food",
                    icon: .init(systemSymbolName: "birthday.cake.fill", accessibilityDescription: "Tab Icon")!,
                    pinnedTabs: [
                        .init(name: "Potato", icon: TabItem.defaultIcon)
                    ],
                    regularTabs: [
                        .init(name: "Recipies", icon: TabItem.defaultIcon),
                        .init(name: "Why do people eat cake?", icon: TabItem.defaultIcon)
                    ]
                ),
                .blankWorkspace(),
                .blankWorkspace()
            ]
        )
    }
}
