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
        addSubview(label)
        addSubview(icon)
        setupConstraints()
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
        label.font = .labelFont(ofSize: 13)
        label.lineBreakMode = .byTruncatingMiddle
    }

    /// Creates the image view
    open func createIcon() -> NSImageView {
        return NSImageView(frame: .zero)
    }

    /// Sets up a given image view
    open func configIcon(icon: NSImageView) {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.symbolConfiguration = .init(pointSize: 13, weight: .regular, scale: .medium)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 15),
            icon.heightAnchor.constraint(equalToConstant: 15),
            icon.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            label.heightAnchor.constraint(equalToConstant: 15),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 3),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    /// *Not Implemented*
    public required init?(coder: NSCoder) {
        fatalError("""
            init?(coder: NSCoder) isn't implemented on `StandardTableViewCell`.
            Please use `.init(frame: NSRect, isEditable: Bool)
            """)
    }
}
