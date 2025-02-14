//
//  CircleView.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 14/2/25.
//

import Cocoa

class CircleView: NSView {
    var circleRadius: CGFloat = 5 {
        didSet { needsDisplay = true } // Redraw when updated
    }
    var circleColor: NSColor = .black {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Get the center of the view
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Define the circle's frame based on the radius
        let circleRect = CGRect(
            x: center.x - circleRadius,
            y: center.y - circleRadius,
            width: circleRadius * 2,
            height: circleRadius * 2
        )

        // Draw the circle
        let circlePath = NSBezierPath(ovalIn: circleRect)
        circleColor.setFill()
        circlePath.fill()
    }
}
