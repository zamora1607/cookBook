//
//  RecipesImport.swift
//  cookBook
//
//  Created by Codex on 27/03/2026.
//

import Foundation

struct RecipesImportPayload: Decodable {
    let exportedAt: Date
    let recipes: [ImportedRecipe]
}

struct ImportedRecipe: Decodable {
    let name: String
    let ingredients: [ImportedIngredient]
    let instructionSteps: [String]
    let keywords: [String]
    let additionalInfo: String?
    let isFavorite: Bool
    let photoDataBase64: String?

    var photoData: Data? {
        guard let photoDataBase64 else {
            return nil
        }

        return Data(base64Encoded: photoDataBase64)
    }
}

struct ImportedIngredient: Decodable {
    let name: String
    let amount: Double
    let unit: String
}
