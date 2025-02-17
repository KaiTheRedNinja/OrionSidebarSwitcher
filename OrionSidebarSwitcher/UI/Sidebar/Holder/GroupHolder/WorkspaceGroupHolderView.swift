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
    /// The watcher that detects when the number or order of workspaces change
    /// (eg. workspaces added, removed, rearranged)
    private var workspacesOrderWatcher: AnyCancellable?

    /// A list of the tab list views. The order does not correspond with the order of the workspaces.
    var tabListViews: [WorkspaceTabListView] = []

    /// The state that the UI is currently in. Should only be set by ``updateUIElements(actions:)``.
    var uiState: WorkspaceGroupHolderUIState!
    /// The horizontal offset, in screen pixels, the views are, during a pan. Will be nil if no pan is
    /// occuring.
    var panHorizontalOffset: CGFloat?

    /// The duration of the workspace switching animation
    var switchAnimationDuration: TimeInterval = 0.3

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        // set up the state
        uiState = .init(shownWorkspaceItem: nil, horizontalOffset: 0, panPreviewWorkspace: nil)

        // Watch the list of workspaces
        watch(
            attribute: wsGroupManager.workspaceGroup.$workspaces,
            storage: &workspacesOrderWatcher
        ) { workspaces in
            self.updateUIElementsForWorkspaceChanges(workspaces: workspaces)
        }

        // Watch the currently focused workspace
        watch(
            attribute: wsGroupManager.workspaceGroup.$focusedWorkspaceID,
            storage: &focusedWorkspaceWatcher
        ) { focusedWorkspaceId in
            self.updateUIElements(
                actions: [
                    .workspaceSelected(focusedWorkspaceId)
                ],
                workspaces: self.wsGroupManager.workspaceGroup.workspaces
            )
        }
    }

    override func layout() {
        guard let wsGroupManager else { return }
        updateUIElements(actions: [], workspaces: wsGroupManager.workspaceGroup.workspaces)
    }
}

extension WorkspaceGroupHolderView: WorkspaceTabListInteractionDelegate {
    func tabWasPressed(tabId: TabItem.ID, inWorkspaceId workspaceId: Workspace.ID) {
        guard let wsGroupManager else { return }
        wsGroupManager.select(tabWithId: tabId, inWorkspaceWithId: workspaceId)
    }
}

/// An object that tracks the state of the workspace group holder's UI
struct WorkspaceGroupHolderUIState: Equatable {
    /// The ID of the currently shown workspace item
    ///
    /// Can be nil if the view has not rendered the selected view yet
    var shownWorkspaceItem: Workspace.ID?
    /// The horizontal offset, in screen pixels, the views are currently offset by. Will be zero if no pan is active.
    var horizontalOffset: CGFloat
    /// The ID of the workspace view that is being "previewed" during a pan, if any
    var panPreviewWorkspace: Workspace.ID?
}

/// An action triggerd by the workspace group holder's UI or the backend
enum WorkspaceGroupHolderAction {
    /// The user has clicked a given workspace icon view
    case workspaceSelected(Workspace.ID)
    /// The given workspace has been removed
    case workspaceRemoved(Workspace.ID)
    /// A workspace has been added at the given insertion point
    case workspaceAdded(Workspace, insertionIndex: Int)
    /// The user is panning and revealing one of the next workspaces
    case panning
    /// The user has stopped panning and it did not result in switching workspace
    case panningCancelled
}
