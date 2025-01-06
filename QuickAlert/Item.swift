//
//  Item.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
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
