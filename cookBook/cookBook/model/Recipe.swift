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
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]
    var instructionSteps: [String]
    var keywords: [String] = []
    var additionalInfo: String?
    var isFavorite: Bool?
    var photoData: Data?
    
    init(
        name: String,
        ingredients: [Ingredient],
        instructionSteps: [String],
        keywords: [String]? = nil,
        additionalInfo: String? = nil,
        isFavorite: Bool = false,
        photoData: Data? = nil
    ) {
        self.name = name
        self.ingredients = ingredients
        self.instructionSteps = instructionSteps
        self.additionalInfo = additionalInfo
        self.keywords = keywords ?? []
        self.isFavorite = isFavorite
        self.photoData = photoData
    }
}
