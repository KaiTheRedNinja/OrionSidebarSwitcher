//
//  WorkspaceGroupHolderView+scroll.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 16/2/25.
//

import Cocoa

extension WorkspaceGroupHolderView {
    override func scrollWheel(with event: NSEvent) {
        guard
            let workspaces = wsGroupManager?.workspaceGroup.workspaces,
            let selectedWorkspaceIndex = workspaces.firstIndex(where: {
                $0.id == wsGroupManager.workspaceGroup.focusedWorkspaceID
            })
        else { return }

        var totalDelta = event.deltaX + event.deltaY
        // if the selected workspace index is first, the totalDelta is not allowed to be negative
        // if the selected workspace index is last, the totalDelta is not allowed to be positive
        if selectedWorkspaceIndex == 0 {
            totalDelta = max(0, totalDelta)
        } else if selectedWorkspaceIndex == workspaces.count - 1 {
            totalDelta = min(0, totalDelta)
        }
        panHorizontalOffset[default: 0] += totalDelta

        switch event.phase {
        case .began, .changed:
            updateUIElements(actions: [.panning], workspaces: workspaces)
        case .ended:
            // if the panning offset is larger than half the width, we switch to the next view
            switchIfScrolledEnough(selectedWorkspaceIndex: selectedWorkspaceIndex)

            // reset the pan and update the UI
            panHorizontalOffset = nil
            updateUIElements(actions: [.panningEnd], workspaces: workspaces)
        case .cancelled:
            // just reset
            panHorizontalOffset = nil
            updateUIElements(actions: [.panningEnd], workspaces: workspaces)
        default: break
        }
    }

    private func switchIfScrolledEnough(selectedWorkspaceIndex: Int) {
        guard let wsGroupManager,
              let panHorizontalOffset
        else { return }

        let workspaces = wsGroupManager.workspaceGroup.workspaces

        if panHorizontalOffset > bounds.width / 2 {
            // switch to the workspace after
            if selectedWorkspaceIndex < workspaces.count - 1 {
                wsGroupManager.focus(workspaceWithId: workspaces[selectedWorkspaceIndex + 1].id)
            }
        } else if panHorizontalOffset < -bounds.width / 2 {
            // switch to the workspace before
            if selectedWorkspaceIndex > 0 {
                wsGroupManager.focus(workspaceWithId: workspaces[selectedWorkspaceIndex - 1].id)
            }
        }
    }
}
