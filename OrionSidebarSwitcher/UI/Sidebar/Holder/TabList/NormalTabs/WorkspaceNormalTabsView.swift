//
//  WorkspaceNormalTabsView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 25/2/25.
//

import Cocoa

class WorkspaceNormalTabsView: NSScrollView {
    var normalTabs: [TabItem]!
    var selectedTab: TabItem.ID?

    /// The interaction delegate, which is forwarded interactions from the tabs
    var interactionDelegate: TabInteractionDelegate?

    /// The outline view holding the tabs
    private var outlineView: NSOutlineView!

    /// The height of each row
    let rowHeight: Double = 26

    /// Setup the ``scrollView`` and ``outlineView``
    func setup() {
        // create an outlineview without a header
        self.outlineView = UnfocusableOutlineView()
        outlineView.headerView = nil
        outlineView.dataSource = self
        outlineView.delegate = self

        // Add a single column for the one column of content.
        // The name of this column will never be shown.
        let column = NSTableColumn(identifier: .init(rawValue: "Cell"))
        column.title = "Cell"
        outlineView.addTableColumn(column)

        // Embed the outlineView in the scrollView, and make sure that the
        // outlineView stays clipped within the scrollView
        self.documentView = outlineView
        self.contentView.automaticallyAdjustsContentInsets = false
        self.contentView.contentInsets = .init(top: 0, left: 0, bottom: 0, right: 0)

        // set the scrollView to only scroll vertically and to hide the scrollers automatically
        self.scrollerStyle = .overlay
        self.hasVerticalScroller = true
        self.hasHorizontalScroller = false
        self.autohidesScrollers = true
        self.drawsBackground = false
        outlineView.rowHeight = rowHeight

        // load the data and expand the first item
        outlineView.reloadData()
        outlineView.expandItem(outlineView.item(atRow: 0))
    }

    func updateUIElements() {
        // get the selected row, and if its different from the current one, change it
        let targetRowIndex = outlineView.row(forItem: selectedTab)
        guard outlineView.selectedRow != targetRowIndex else { return }
        outlineView.reloadData()
        outlineView.selectRowIndexes(.init(integer: targetRowIndex), byExtendingSelection: true)
    }

    /// We forward scroll events to the parent so that it can process workspace panning
    /// events, but only when horizontal panning > vertical panning so that the outline view
    /// can still operate normally
    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ||  // is a horizontal scroll
           [NSEvent.Phase.ended, .cancelled].contains(event.phase) {   // or is an ending event
            self.superview?.scrollWheel(with: event)
        }
        super.scrollWheel(with: event)
    }
}

extension WorkspaceNormalTabsView: NSOutlineViewDataSource, NSOutlineViewDelegate {
    // Providing a view for a given item in a column
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tabId = item as? TabItem.ID, let tab = normalTabs.first(where: { $0.id == tabId }) else { return nil }

        let cell = StandardTableViewCell(frame: .zero)
        cell.icon.image = tab.icon
        cell.label.stringValue = tab.name
        return cell
    }

    // The number of children an item has
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item == nil else { return 0 }
        return normalTabs.count
    }

    // The child at an index of an item
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        assert(item == nil, "Items do not have children")
        assert(index >= 0 && index < normalTabs.count, "Requested index must exist")
        return normalTabs[index].id
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool { false }
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat { rowHeight }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow

        guard selectedRow >= 0 && selectedRow < normalTabs.count,
              let selectedItem = outlineView.item(atRow: selectedRow) as? TabItem.ID
        else { return }

        interactionDelegate?.tabWasPressed(tabId: selectedItem)
    }
}

/// Makes the selection gray
class UnfocusableOutlineView: NSOutlineView {
    override var acceptsFirstResponder: Bool { false }
}
