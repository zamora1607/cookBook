//
//  Recipe.swift
//  cookBook
//
//  Created by Ania on 03/01/2025.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    var name: String
    var ingredients: [Ingredient]
    var instructions: String
    var keywords: [String] = []
    var additionalInfo: String?
    
    init(
        name: String,
        ingredients: [Ingredient],
        instructions: String,
        keywords: [String]? = nil,
        additionalInfo: String? = nil
    ) {
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.additionalInfo = additionalInfo
        self.keywords = keywords ?? []
    }
}
