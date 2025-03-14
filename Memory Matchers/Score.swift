//
//  Persistence.swift
//  Memory Matchers
//
//  Created by Justin Whitt on 3/14/25.
//

import SwiftData
import Foundation

@Model
class Score: Identifiable {
    var id: UUID
    var name: String
    var time: Double
    var game: String
    
    init(name: String, time: Double, game: String) {
        self.id = UUID()
        self.name = name
        self.time = time
        self.game = game
    }
}
