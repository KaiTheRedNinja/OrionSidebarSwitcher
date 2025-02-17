//
//  WorkspacePinnedTabsView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 17/2/25.
//

import Cocoa

class WorkspacePinnedTabsView: NSView {
    var pinnedTabs: [TabItem]!
    var selectedTab: TabItem.ID?

    var pinnedTabViews: [PinnedTabView] = []

    func setup() {
        // create the pinned tab views
        for tab in pinnedTabs {
            let pinnedTabView = PinnedTabView()
            pinnedTabView.tabItem = tab
            pinnedTabView.setup()
            pinnedTabViews.append(pinnedTabView)
            self.addSubview(pinnedTabView)
        }
    }

    func idealHeight(forWidth width: CGFloat) -> CGFloat {
        // determine the number of columns
        let columns = columnCount(forWidth: width)
        // Using that, determine how many rows there are. For example, if ther
        // are 3 colums and 6 items, there are 2 rows. If there are 7, then theres 3.
        let rows = (CGFloat(pinnedTabs.count)/CGFloat(columns)).rounded(.up)

        return rows * PinnedTabView.tabItemHeight
    }

    override func layout() {
        updateUIElements()
    }

    override var isFlipped: Bool { true }

    func updateUIElements() {
        guard let pinnedTabs else { return }

        let columns = columnCount(forWidth: frame.width)
        for (index, pinnedTab) in pinnedTabs.enumerated() {
            let column = index%columns
            let row = index/columns
            let targetFrame = CGRect(
                x: PinnedTabView.tabItemHeight * CGFloat(column),
                y: PinnedTabView.tabItemHeight * CGFloat(row),
                width: PinnedTabView.tabItemHeight,
                height: PinnedTabView.tabItemHeight
            )

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pinnedTabViews
                    .first { $0.tabItem.id == pinnedTab.id }?
                    .animator()
                    .frame = targetFrame
            }
        }
    }

    private func columnCount(forWidth width: CGFloat) -> Int {
        // The number of columns is largest whole
        // number of tab items it can fit horizontally
        Int(width/PinnedTabView.tabItemHeight)
    }
}

class PinnedTabView: NSView {
    var tabItem: TabItem!

    static let tabItemHeight: CGFloat = 40

    func setup() {
        wantsLayer = true
        layer?.borderWidth = 1
        layer?.borderColor = .init(red: 1, green: 1, blue: 0, alpha: 1)
    }
}
