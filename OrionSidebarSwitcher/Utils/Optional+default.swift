//
//  Optional+default.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

extension Optional {
    /// Offers an ergonomic way to edit an optional's property, similar to `Dictionary`'s default subscript
    subscript(default defaultValue: Wrapped) -> Wrapped {
        get {
            self ?? defaultValue
        }
        mutating set(newValue) {
            self = newValue
        }
    }
}
