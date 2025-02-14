//
//  WorkspaceSwitcherView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 12/2/25.
//

import Cocoa
import Combine

class WorkspaceSwitcherView: NSView {
    /// A weak reference to the workspace group manager
    weak var wsGroupManager: WorkspaceGroupManager!

    /// The watcher that detects when the focused workspace changes
    private var focusedWorkspaceWatcher: AnyCancellable?
    /// The watcher that detects when the number or order of workspaces change
    /// (eg. workspaces added, removed, rearranged)
    private var workspacesOrderWatcher: AnyCancellable?

    /// A list of the icon views. The order does not correspond with the order of the workspaces.
    var workspaceIconViews: [WorkspaceIconView] = []

    /// The state that the UI is currently in. Should only be set by ``updateUIElements(actions:)``.
    var uiState: WorkspaceSwitcherUIState!

    /// Sets up the workspace switcher view's UI and listeners
    func setup() {
        // Add the separators to the view
        addSeparators()

        // Set up the UI state object
        uiState = .init(
            isCompact: false,
            hoveredWorkspaceId: nil,
            selectedWorkspaceItem: wsGroupManager.workspaceGroup.focusedWorkspaceID
        )

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
        // Watch the list of workspaces
        watch(
            attribute: wsGroupManager.workspaceGroup.$workspaces,
            storage: &workspacesOrderWatcher,
            call: self.updateUIElementsForWorkspaceChanges()
        )

        // updateUIElements() is called by the watchers, so we don't need to manually call it.
    }

    override func layout() {
        super.layout()
        guard let wsGroupManager else { return }
        updateUIElements(actions: [], workspaces: wsGroupManager.workspaceGroup.workspaces)
        addSeparators()
    }

    /// Adds the separators at the top and bottom of the switcher view
    private func addSeparators() {
        wantsLayer = true

        // delete all existing sublayers
        layer?.sublayers?.removeAll()

        let topBorder = CALayer()
        topBorder.backgroundColor = NSColor.separatorColor.cgColor
        topBorder.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)

        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = NSColor.separatorColor.cgColor
        bottomBorder.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)

        layer?.addSublayer(topBorder)
        layer?.addSublayer(bottomBorder)
    }
}

// To recieve updates from the individual icon views
extension WorkspaceSwitcherView: WorkspaceIconInteractionDelegate {
    func workspaceIconMouseEntered(_ workspaceId: Workspace.ID) {
        guard let wsGroupManager else { return }
        updateUIElements(
            actions: [.workspaceHovered(workspaceId)],
            workspaces: wsGroupManager.workspaceGroup.workspaces
        )
    }

    func workspaceIconMouseExited(_ workspaceId: Workspace.ID) {
        guard let wsGroupManager else { return }
        updateUIElements(
            actions: [.workspaceUnhovered(workspaceId)],
            workspaces: wsGroupManager.workspaceGroup.workspaces
        )
    }

    func workspaceIconMouseClicked(_ workspaceId: Workspace.ID) {
        guard let wsGroupManager else { return }
        wsGroupManager.focus(workspaceWithId: workspaceId)
        updateUIElements(
            actions: [.workspaceSelected(workspaceId)],
            workspaces: wsGroupManager.workspaceGroup.workspaces
        )
    }
}

/// An object that tracks the state of the workspace switcher's UI
struct WorkspaceSwitcherUIState: Equatable {
    /// Whether or not the switcher view's UI is in compact mode
    var isCompact: Bool

    /// The ID of the workspace item that is being hovered on, if any
    var hoveredWorkspaceId: Workspace.ID?

    /// The ID of the selected workspace item
    var selectedWorkspaceItem: Workspace.ID
}

/// An action triggerd by the workspace switcher's UI or the backend
///
/// Note that determining if the sidebar should be in compact mode is the responsibility
/// of the `updateUIElements` function itself.
enum WorkspaceSwitcherAction {
    /// The mouse has entered a given workspace icon view
    case workspaceHovered(Workspace.ID)
    /// The mouse has exited a given workspace icon view
    case workspaceUnhovered(Workspace.ID)
    /// The user has clicked a given workspace icon view
    case workspaceSelected(Workspace.ID)
    /// The given workspace has been removed
    case workspaceRemoved(Workspace.ID)
    /// A workspace has been added at the given insertion point
    case workspaceAdded(Workspace, insertionIndex: Int)
}
