//
//  RecipesExportDocument.swift
//  cookBook
//
//  Created by Codex on 27/03/2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct RecipesExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(recipes: [Recipe]) {
        let exportPayload = RecipesExportPayload(recipes: recipes.map(RecipeExport.init))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        data = (try? encoder.encode(exportPayload)) ?? Data("[]".utf8)
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct RecipesExportPayload: Codable {
    let exportedAt: Date
    let recipes: [RecipeExport]

    init(recipes: [RecipeExport], exportedAt: Date = .now) {
        self.exportedAt = exportedAt
        self.recipes = recipes
    }
}

private struct RecipeExport: Codable {
    let name: String
    let ingredients: [IngredientExport]
    let instructionSteps: [String]
    let keywords: [String]
    let additionalInfo: String?
    let isFavorite: Bool
    let photoDataBase64: String?

    init(recipe: Recipe) {
        name = recipe.name
        ingredients = recipe.ingredients.map(IngredientExport.init)
        instructionSteps = recipe.instructionSteps.normalizedInstructionSteps
        keywords = recipe.keywords
        additionalInfo = recipe.additionalInfo
        isFavorite = recipe.isFavorite ?? false
        photoDataBase64 = recipe.photoData?.base64EncodedString()
    }
}

private struct IngredientExport: Codable {
    let name: String
    let amount: Double
    let unit: String

    init(ingredient: Ingredient) {
        name = ingredient.name
        amount = ingredient.amount
        unit = ingredient.unit
    }
}
