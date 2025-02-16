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

    /// Sets up the workspace group holder's UI and listeners
    func setup() {
        // set up the state
        uiState = .init(shownWorkspaceItem: nil)

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

    /// A function that wraps ``updateUIElements(actions:)`` by determining which workspaces have been added/removed
    func updateUIElementsForWorkspaceChanges(workspaces: [Workspace]) {
        // determine the current on-screen items, and the new workspace items
        let currentWorkspaceItems = Set(tabListViews.map { $0.workspace.id })
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

    override func layout() {
        guard let wsGroupManager else { return }
        updateUIElements(actions: [], workspaces: wsGroupManager.workspaceGroup.workspaces)
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
    func updateUIElements( // swift lint:disable:this function_body_length cyclomatic_complexity
        actions: [WorkspaceGroupHolderAction],
        workspaces: [Workspace]
    ) {
        print("------START------")
        for action in actions {
            switch action {
            case .workspaceSelected(let wsId):
                print("Workspace selected: \(workspaces.first(where: { $0.id == wsId })?.name ?? "not found")")
            case .workspaceRemoved(let wsId):
                print("Workspace removed: \(workspaces.first(where: { $0.id == wsId })?.name ?? "not found")")
            case .workspaceAdded(let workspace, _):
                print("Workspace added: \(workspace.name)")
            }
        }

        // --- 1. Determine the frame that the focused tab view should take up ---
        let focusedTabViewFrame = self.bounds

        // --- 2. Execute the actions ---
        var workspaceToShow = uiState.shownWorkspaceItem
        var workspacesToRemove: Set<Workspace.ID> = []
        for action in actions {
            switch action {
            case let .workspaceSelected(workspaceId):
                workspaceToShow = workspaceId
            case let .workspaceRemoved(workspaceId):
                workspacesToRemove.insert(workspaceId)
            case let .workspaceAdded(workspace, _):
                let tabListView = WorkspaceTabListView()
                tabListView.workspace = workspace
                tabListView.setup()
                tabListViews.append(tabListView)
            }
        }

        print("Workspace to show: \(workspaces.first(where: { $0.id == workspaceToShow })?.name ?? "not found")")
        print("-------END-------")

//        let currentWorkspaceIndex = workspaces.firstIndex(where: { $0.id == uiState.shownWorkspaceItem })
//
//        // if the current workspace index doesn't exist, simply add it in and return
//        guard let currentWorkspaceIndex else {
//            if let currentWorkspace = tabListViews.first(where: { $0.workspace.id == workspaceToShow }) {
//                addSubview(currentWorkspace)
//                currentWorkspace.frame = focusedTabViewFrame
//            }
//            return
//        }
//
//        guard let workspaceToShowIndex = workspaces.firstIndex(where: { $0.id == workspaceToShow })
//        else {
//            return
//        }
//
//        // --- 3. If the selected workspace has changed ---
//        guard workspaceToShowIndex != currentWorkspaceIndex else { return }
//        // Determine which direction the new workspace is coming from
//
//        let isComingFromRight = currentWorkspaceIndex < workspaceToShowIndex
//        let newWorkspaceFrame = CGRect(
//            x: isComingFromRight
//                ? focusedTabViewFrame.maxX
//                : focusedTabViewFrame.minX-focusedTabViewFrame.width,
//            y: 0,
//            width: focusedTabViewFrame.width,
//            height: focusedTabViewFrame.height
//        )
//        let oldWorkspaceFrame = CGRect(
//            x: !isComingFromRight
//                ? focusedTabViewFrame.maxX
//                : focusedTabViewFrame.minX-focusedTabViewFrame.width,
//            y: 0,
//            width: focusedTabViewFrame.width,
//            height: focusedTabViewFrame.height
//        )
//
//        for tabListView in tabListViews {
//            if tabListView.workspace.id == uiState.shownWorkspaceItem {
//                // Animate out the old workspace
//                NSAnimationContext.runAnimationGroup { context in
//                    context.duration = 1
//                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//                    tabListView.animator().frame = oldWorkspaceFrame
//                }
//                // After the animation, remove the old workspace from this view
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//                    tabListView.removeFromSuperview()
//
//                    // if its to be removed, remove it completely
//                    if workspacesToRemove.contains(tabListView.workspace.id) {
//                        self?.tabListViews.removeAll { $0.workspace.id == tabListView.workspace.id }
//                    }
//                }
//            } else if tabListView.workspace.id == workspaceToShow {
//                // Add the new workspace to this view, out of frame
//                tabListView.frame = newWorkspaceFrame
//                addSubview(tabListView)
//
//                // Animate in the new workspace
//                NSAnimationContext.runAnimationGroup { context in
//                    context.duration = 1
//                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//                    tabListView.animator().frame = focusedTabViewFrame
//                }
//            } else if workspacesToRemove.contains(tabListView.workspace.id) {
//                // workspace is to be removed immediately since it isn't shown at all
//                tabListViews.removeAll { $0.workspace.id == tabListView.workspace.id }
//            }
//        }
    }
}

/// An object that tracks the state of the workspace group holder's UI
struct WorkspaceGroupHolderUIState: Equatable {
    /// The ID of the currently shown workspace item
    ///
    /// Can be nil if the view has not rendered the selected view yet
    var shownWorkspaceItem: Workspace.ID?
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
