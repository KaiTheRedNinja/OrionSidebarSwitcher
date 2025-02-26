# OrionSidebarSwitcher
Orion Sidebar Switcher Technical Challenge

## Todo List

Roughly based on the specifications at https://hackmd.io/@kagi/S1hXCgYFkg

- [x] Basic window layout
- [x] Collapsible and resizable sidebar 
- [x] Top navigation stack to navigate between different workspaces.
    - [x] Add/remove workspace capability and animation
    - [x] Workspace icons collapse to dots when there’s less space available, and animate to full size on hover
    - [x] When theres too many workspace items, scroll
- [x] Workspace content holder
    - [x] Smooth animation while switching to different workspace.
    - [x] Pan gesture to swipe between workspaces.
        - [x] Use pan gesture to swipe between multiple workspaces
    - [x] Pinned tabs
    - [x] Normal tabs
    - [x] Indicator for current tab
- [x] Image in content area which should also be animated while switching workspace.
- [x] Example workspace data must have some pinned/normal items in sidebar

## Implementation Details

### Inter-object Interaction and UI State Management

Most views in this project have several of these four parts:
- A State Struct, responsible for holding information about the state that the view is currently displaying 
- An Action Enumeration, which outlines the actions that external objects (eg. its parent view) can execute
- An `updateUIElements` function, which takes in the Action Enumeration and updates the UI accordingly
- An Interaction Protocol, which another object can set itself as to recieve actions from the view (eg. clicks)

For example, the `WorkspaceSwitcherView` has three of them:
- A State Struct, `WorkspaceSwitcherUIState`
- An Action Enumeration, `WorkspaceSwitcherAction`
- An `updateUIElements` function

The switcher manages the `WorkspaceIconView`s corresponding to each workspace, and sets itself as each of
their `WorkspaceIconInteractionDelegate`s. When the user clicks on an item, this is what occurs:
1. `WorkspaceIconView` detects the press
2. `WorkspaceIconView` informs its interaction delegate of the click (ie, its parent, `WorkspaceSwitcherView`)
3. `WorkspaceSwitcherView` informs the `WorkspaceGroupManager` to change the currently focused workspace
4. `WorkspaceGroupManager` changes the focused workspace in its held state, which updates its combine publisher
5. `WorkspaceSwitcherView` is subscribed to the focused workspace's publisher, and recieves the update
6. It calls its `updateUIElements` function, passing `.workspaceSelected(FOCUSED_WORKSPACE_ID)` as the action
7. `updateUIElements` then does the required redraws

This allows interaction, UI, and state to be kept separate and modular, since they only interact through protocols
and publishers.
