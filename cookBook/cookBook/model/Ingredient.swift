//
//  Ingridient.swift
//  cookBook
//
//  Created by Ania on 03/01/2025.
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var amount: Double
    var unit: String
    
    init(name: String, amount: Double, unit: String) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}
