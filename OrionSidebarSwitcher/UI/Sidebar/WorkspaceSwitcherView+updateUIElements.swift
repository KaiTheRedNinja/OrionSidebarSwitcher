//
//  WorkspaceSwitcherView+updateUIElements.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

extension WorkspaceSwitcherView {
    /// Called to update the UI.
    ///
    /// It does the following:
    /// 1. Determine if the following aspects have changed:
    ///     - Whether the sidebar is full enough to warrant switching to compact mode
    ///     - Which item is currently being hovered, if the sidebar is in compact mode
    ///     - Which item is currently being selected
    ///     - If any workspaces have been removed
    ///     - If any workspaces have been added
    /// 2. For each workspace, calculate its new size/position within the sidebar
    /// 3. For each workspace,
    ///     - If an icon view for it already exists - Move the view to its new position with an animation
    ///     - If an icon view for it doesn't exist - Create a new view with zero size and centered at
    ///     where its meant to appear, then animate it filling up to full size
    ///     - After that, update it to the correct rendering state (eg. compact, selected, hovering, default)
    /// 4. If the selected item has changed, animate it shrinking then expanding back to normal size
    func updateUIElements() {
    }
}
