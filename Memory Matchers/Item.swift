//
//  Item.swift
//  Memory Matchers
//
//  Created by Justin Whitt on 3/8/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
