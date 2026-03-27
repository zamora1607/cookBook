import SwiftUI
import ImageIO
import UniformTypeIdentifiers

struct IngredientDraft: Identifiable {
    let id = UUID()
    var name = ""
    var amountText = ""
    var unit = ""

    init() {}

    init(ingredient: Ingredient) {
        name = ingredient.name
        amountText = ingredient.amount == 0 ? "" : ingredient.amount.formatted()
        unit = ingredient.unit
    }

    var ingredientData: IngredientFormData? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return nil
        }

        return IngredientFormData(
            name: trimmedName,
            amount: Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct InstructionDraft: Identifiable {
    let id = UUID()
    var text = ""

    init() {}

    init(text: String) {
        self.text = text
    }
}

enum InstructionFocusField: Hashable {
    case step(UUID)
}

enum IngredientFieldKind {
    case name
    case amount
    case unit
}

enum IngredientFocusField: Hashable {
    case name(UUID)
    case amount(UUID)
    case unit(UUID)
}

struct RecipeFormData {
    let name: String
    let ingredients: [IngredientFormData]
    let instructionSteps: [String]
    let keywords: [String]
    let additionalInfo: String?
    let photoData: Data?
}

struct IngredientFormData {
    let name: String
    let amount: Double
    let unit: String
}

extension Ingredient {
    convenience init(_ formData: IngredientFormData) {
        self.init(name: formData.name, amount: formData.amount, unit: formData.unit)
    }
}

extension String {
    var cleanedOptionalString: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension Array where Element == String {
    var normalizedInstructionSteps: [String] {
        map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum RecipePhotoProcessor {
    static let maximumPixelSize = 1600
    static let compressionQuality: CGFloat = 0.82

    static func optimizedJPEGData(from fileURL: URL) throws -> Data {
        let startedAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw RecipePhotoImportError.unreadableImage
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw RecipePhotoImportError.unreadableImage
        }

        let destinationData = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(
            destinationData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw RecipePhotoImportError.encodingFailed
        }

        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        CGImageDestinationAddImage(imageDestination, cgImage, destinationOptions as CFDictionary)

        guard CGImageDestinationFinalize(imageDestination) else {
            throw RecipePhotoImportError.encodingFailed
        }

        return destinationData as Data
    }
}

enum RecipePhotoImportError: LocalizedError {
    case unreadableImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return AppLocalization.photoUnreadableErrorText()
        case .encodingFailed:
            return AppLocalization.photoEncodingErrorText()
        }
    }
}
