//
//  Item.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
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
