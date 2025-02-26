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
    var padding: CGFloat = 6

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

        updateUIElements()
    }

    func idealHeight(forWidth width: CGFloat) -> CGFloat {
        // determine the number of columns
        let columns = columnCount(forWidth: width)
        // Using that, determine how many rows there are. For example, if ther
        // are 3 colums and 6 items, there are 2 rows. If there are 7, then theres 3.
        let rows = (CGFloat(pinnedTabs.count)/CGFloat(columns)).rounded(.up)

        return rows * (PinnedTabView.tabItemSize.height + padding)
    }

    override func layout() {
        updateUIElements()
    }

    override var isFlipped: Bool { true }

    func updateUIElements() {
        guard let pinnedTabs else { return }

        let tabItemPaddedWidth: CGFloat = PinnedTabView.tabItemSize.width + padding
        let tabItemPaddedHeight: CGFloat = PinnedTabView.tabItemSize.height + padding

        let columns = columnCount(forWidth: frame.width)
        for (index, pinnedTab) in pinnedTabs.enumerated() {
            guard let targetTabView = pinnedTabViews
                .first(where: { $0.tabItem.id == pinnedTab.id })
            else { continue }

            // update the tab's selection state
            targetTabView.isSelected = pinnedTab.id == selectedTab
            targetTabView.updateUIElements()

            // there must be enough space to display pinned tabs
            guard columns > 0 else { continue }

            // calculate the position of the view
            let column = index%columns
            let row = index/columns
            let targetFrame = CGRect(
                origin: .init(
                    x: tabItemPaddedWidth * CGFloat(column),
                    y: tabItemPaddedHeight * CGFloat(row)
                ),
                size: PinnedTabView.tabItemSize
            )

            // move the view to its new position, animating if needed
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
        // we add the padding to the width to account for the last tab's trailing padding
        Int((width+padding)/(PinnedTabView.tabItemSize.width+padding))
    }
}
