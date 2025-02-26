//
//  WorkspaceNormalTabsView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 25/2/25.
//

import Cocoa

class WorkspaceNormalTabsView: NSScrollView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    public var outlineView: NSOutlineView!

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

    // Providing a view for a given item in a column
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = StandardTableViewCell(frame: .zero)
        cell.icon.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "globe")
        cell.label.stringValue = "\(item)"
        return cell
    }

    // The number of children an item has
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item != nil {
            0
        } else {
            // TODO: number of tabs
            10
        }
    }

    // The child at an index of an item
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        assert(item == nil, "Items do not have children")
        // TODO: actual tab reference
        return index
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        false
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        rowHeight
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        print("Selection changed!")
    }
}

/// Makes the selection gray
class UnfocusableOutlineView: NSOutlineView {
    override var acceptsFirstResponder: Bool { false }
}
