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

    /// The interaction delegate, which is forwarded interactions from the tabs
    var interactionDelegate: TabInteractionDelegate?

    /// How much spacing the contents have between each other
    var padding: CGFloat = 3

    func setup() {
        // create the pinned tab views
        for tab in pinnedTabs {
            let pinnedTabView = PinnedTabView()
            pinnedTabView.tabItem = tab
            pinnedTabView.setup()
            pinnedTabView.interactionDelegate = interactionDelegate
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

        let tabItemPaddedHeight: CGFloat = PinnedTabView.tabItemHeight + padding

        let columns = columnCount(forWidth: frame.width)
        for (index, pinnedTab) in pinnedTabs.enumerated() {
            let column = index%columns
            let row = index/columns
            let targetFrame = CGRect(
                x: tabItemPaddedHeight * CGFloat(column),
                y: tabItemPaddedHeight * CGFloat(row),
                width: PinnedTabView.tabItemHeight,
                height: PinnedTabView.tabItemHeight
            )
            guard let targetTabView = pinnedTabViews
                .first(where: { $0.tabItem.id == pinnedTab.id })
            else { continue }

            if targetTabView.frame == .zero {
                // the tab view hasn't been set up yet, so move it immediately
                targetTabView.frame = targetFrame
            } else {
                // animate it smoothly
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    targetTabView.animator().frame = targetFrame
                }
            }
        }
    }

    private func columnCount(forWidth width: CGFloat) -> Int {
        // The number of columns is largest whole
        // number of tab items it can fit horizontally
        Int(width/(PinnedTabView.tabItemHeight+padding))
    }
}
