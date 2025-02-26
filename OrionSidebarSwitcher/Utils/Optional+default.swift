//
//  Optional+default.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

extension Optional {
    subscript(default defaultValue: Wrapped) -> Wrapped {
        get {
            self ?? defaultValue
        }
        mutating set(newValue) {
            self = newValue
        }
    }
}
