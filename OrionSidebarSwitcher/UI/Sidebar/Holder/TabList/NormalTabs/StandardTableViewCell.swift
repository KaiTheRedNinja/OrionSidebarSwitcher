//
//  StandardTableViewCell.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

import Foundation
import SwiftUI

/// A reusable Table View Cell with a label, secondary label, and icon
open class StandardTableViewCell: NSTableCellView {
    /// The main text to display
    public weak var label: NSTextField!
    /// The icon, at the leading edge of the cell
    public weak var icon: NSImageView!

    /// Initializes the `TableViewCell` with an `icon` and `label`
    /// Both the icon and label will be colored, and sized based on the user's preferences.
    /// - Parameters:
    ///   - frameRect: The frame of the cell.
    ///   - item: The file item the cell represents.
    ///   - isEditable: Set to true if the user should be able to edit the file name.
    public init(frame frameRect: NSRect, isEditable: Bool = true) {
        super.init(frame: frameRect)
        setupViews(frame: frameRect, isEditable: isEditable)
    }

    /// Default init, assumes isEditable to be false
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews(frame: frameRect, isEditable: false)
    }

    private func setupViews(frame frameRect: NSRect, isEditable: Bool) {
        // Create the label
        let label = createLabel()
        self.label = label
        configLabel(label: self.label, isEditable: isEditable)
        self.textField = label

        // Create the icon
        let icon = createIcon()
        self.icon = icon
        configIcon(icon: icon)
        imageView = icon

        // add constraints
        createConstraints(frame: frameRect)
        addSubview(label)
        addSubview(icon)
    }

    // MARK: Create and config stuff
    /// Creates the label
    open func createLabel() -> NSTextField {
        return NSTextField(frame: .zero)
    }

    /// Sets up a given label with a given editability
    open func configLabel(label: NSTextField, isEditable: Bool) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.isBordered = false
        label.isEditable = isEditable
        label.isSelectable = isEditable
        label.layer?.cornerRadius = 10.0
        label.font = .labelFont(ofSize: fontSize)
        label.lineBreakMode = .byTruncatingMiddle
    }

    /// Creates the image view
    open func createIcon() -> NSImageView {
        return NSImageView(frame: .zero)
    }

    /// Sets up a given image view
    open func configIcon(icon: NSImageView) {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.symbolConfiguration = .init(pointSize: fontSize, weight: .regular, scale: .medium)
    }

    /// Contrains the views. Currently only redirects to ``resizeSubviews(withOldSize:)``
    open func createConstraints(frame frameRect: NSRect) {
        resizeSubviews(withOldSize: .zero)
    }

    let iconWidth: CGFloat = 22

    /// Positions all the views
    override public func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)

        icon.frame = NSRect(
            x: 2, y: 4,
            width: iconWidth, height: frame.height
        )

        label.frame = NSRect(
            x: 2+iconWidth,
            y: 2.8,
            width: frame.width - iconWidth - 2,
            height: 22
        )
    }

    /// *Not Implemented*
    public required init?(coder: NSCoder) {
        fatalError("""
            init?(coder: NSCoder) isn't implemented on `StandardTableViewCell`.
            Please use `.init(frame: NSRect, isEditable: Bool)
            """)
    }

    /// Returns the font size for the current row height. Defaults to `13.0`
    private var fontSize: Double {
        switch self.frame.height {
        case 20: return 11
        case 22: return 13
        case 24: return 14
        default: return 13
        }
    }
}
