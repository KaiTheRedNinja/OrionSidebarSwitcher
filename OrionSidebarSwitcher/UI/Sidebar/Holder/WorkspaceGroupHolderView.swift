//
//  WorkspaceGroupHolderView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class WorkspaceGroupHolderView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    private var focusedWorkspaceWatcher: AnyCancellable?

    /// A list of the tab list views. The order does not correspond with the order of the workspaces.
    var tabListViews: [WorkspaceTabListView] = []

    /// The state that the UI is currently in. Should only be set by ``updateUIElements(actions:)``.
    var uiState: WorkspaceGroupHolderUIState!

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        // for each workspace, create a tab list view
        for workspace in wsGroupManager.workspaceGroup.workspaces {
            let tabListView = WorkspaceTabListView()
            tabListView.workspace = workspace
            tabListView.setup()
            tabListViews.append(tabListView)
        }

        // set up the state
        uiState = .init(shownWorkspaceItem: wsGroupManager.workspaceGroup.focusedWorkspaceID)

        // Watch the currently focused workspace
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceWatcher,
            call: self.updateUIElements(
                actions: [
                    .workspaceSelected(self.wsGroupManager.workspaceGroup.focusedWorkspaceID)
                ],
                workspaces: self.wsGroupManager.workspaceGroup.workspaces
            )
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
    /// 3. If the selected workspace has changed:
    ///     a. Determine which direction the new workspace is coming from
    ///     b. Add the new workspace to this view, out of frame
    ///     c. Animate out the old workspace, and animate in the new workspace
    ///     d. After the animation, remove the old workspace from this view
    /// 4. Else, just resize the currently focused workspace
    /// 5. Update the UI state
    func updateUIElements(actions: [WorkspaceGroupHolderAction], workspaces: [Workspace]) {
    }
}

/// An object that tracks the state of the workspace group holder's UI
struct WorkspaceGroupHolderUIState: Equatable {
    /// The ID of the currently shown workspace item
    var shownWorkspaceItem: Workspace.ID
}

/// An action triggerd by the workspace group holder's UI or the backend
enum WorkspaceGroupHolderAction {
    /// The user has clicked a given workspace icon view
    case workspaceSelected(Workspace.ID)
    /// The given workspace has been removed
    case workspaceRemoved(Workspace.ID)
    /// A workspace has been added at the given insertion point
    case workspaceAdded(Workspace, insertionIndex: Int)
}
