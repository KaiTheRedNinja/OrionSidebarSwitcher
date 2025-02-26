//
//  Combine+watch.swift
//  OrionSidebarSwitcher
//
//  Created by Kai Quan Tay on 26/2/25.
//

import Combine

/// Watches a published attribute, by storing it in a cancellable and calling a closure during publishes
/// - Parameters:
///   - attribute: The publisher to watch
///   - storage: The cancellable to store the watcher in
///   - call: A callback, triggered whenever the storage updates
func watch<P: Publisher>(
    attribute: P,
    storage: inout AnyCancellable?,
    call: @escaping (P.Output) -> Void
) where P.Failure == Never {
    // Cancel whatever is in the storage
    storage?.cancel()
    // Create a new watcher
    storage = attribute.sink { output in
        call(output)
    }
}
