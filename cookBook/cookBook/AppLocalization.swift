import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case polish = "pl"
    case english = "en"

    var id: String { rawValue }
}

@MainActor
final class AppLocalization: ObservableObject {
    static let shared = AppLocalization()
    nonisolated static let storageKey = "appLanguage"

    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        selectedLanguage = Self.resolvedLanguage()
    }

    nonisolated static func resolvedLanguage() -> AppLanguage {
        if
            let storedValue = UserDefaults.standard.string(forKey: storageKey),
            let storedLanguage = AppLanguage(rawValue: storedValue)
        {
            return storedLanguage
        }

        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferredLanguage.hasPrefix("pl") ? .polish : .english
    }

    nonisolated static func bundle(for language: AppLanguage) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }

    nonisolated static func localizedString(
        _ key: String,
        default defaultValue: String,
        language: AppLanguage
    ) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle(for: language),
            value: defaultValue,
            comment: ""
        )
    }

    private func text(_ key: String, default defaultValue: String) -> String {
        Self.localizedString(key, default: defaultValue, language: selectedLanguage)
    }

    private func format(_ key: String, default defaultValue: String, _ arguments: CVarArg...) -> String {
        String(
            format: text(key, default: defaultValue),
            locale: Locale(identifier: selectedLanguage.rawValue),
            arguments: arguments
        )
    }

    func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .polish:
            return text("language.polish", default: "Polish")
        case .english:
            return text("language.english", default: "English")
        }
    }

    var toolbarLanguage: String { text("language.menu", default: "Language") }

    func favoriteAction(isFavorite: Bool) -> String {
        isFavorite
            ? text("favorite.remove", default: "Remove from Favorites")
            : text("favorite.add", default: "Add to Favorites")
    }

    var editRecipe: String { text("recipe.edit", default: "Edit Recipe") }
    var deleteRecipe: String { text("recipe.delete", default: "Delete Recipe") }
    var searchPrompt: String { text("search.prompt", default: "Search by keyword") }
    var noRecipesTitle: String { text("empty.no_recipes.title", default: "No Recipes Yet") }
    var noRecipesDescription: String { text("empty.no_recipes.description", default: "Use the plus button to create your first recipe.") }
    var noMatchesTitle: String { text("empty.no_matches.title", default: "No Matching Recipes") }
    var noMatchesDescription: String { text("empty.no_matches.description", default: "Try a different keyword.") }
    var selectRecipeTitle: String { text("empty.select_recipe.title", default: "Select a Recipe") }
    var selectRecipeDescription: String { text("empty.select_recipe.description", default: "Choose a recipe from the list to preview it here.") }
    var importRecipes: String { text("recipes.import", default: "Import Recipes") }
    var exportRecipes: String { text("recipes.export", default: "Export Recipes") }
    var addRecipe: String { text("recipe.add", default: "Add Recipe") }
    var exportFilename: String { text("export.filename", default: "cookbook-recipes") }
    var exportFailedTitle: String { text("error.export_failed.title", default: "Export Failed") }
    var importFailedTitle: String { text("error.import_failed.title", default: "Import Failed") }
    var unknownError: String { text("error.unknown", default: "An unknown error occurred.") }
    var deleteRecipeTitle: String { text("confirm.delete_recipe.title", default: "Delete Recipe?") }
    var delete: String { text("action.delete", default: "Delete") }
    var cancel: String { text("action.cancel", default: "Cancel") }
    var importCompleteTitle: String { text("toast.import_complete.title", default: "Import Complete") }
    var importEmptyMessage: String { text("toast.import_complete.empty", default: "The file did not contain any recipes to import.") }
    var recipeSectionTitle: String { text("section.recipe.title", default: "Recipe") }
    var recipeSectionSubtitle: String { text("section.recipe.subtitle", default: "Set the basics first. Keywords stay comma-separated for search.") }
    var instructionsSectionTitle: String { text("section.instructions.title", default: "Instructions") }
    var instructionsSectionSubtitle: String { text("section.instructions.subtitle", default: "Keep one step per row. Press Enter on an empty last step to move to ingredients.") }
    var describeStepPlaceholder: String { text("placeholder.describe_step", default: "Describe this step") }
    var addStep: String { text("action.add_step", default: "Add Step") }
    var jumpToIngredients: String { text("action.jump_to_ingredients", default: "Jump to Ingredients") }
    var ingredientsSectionTitle: String { text("section.ingredients.title", default: "Ingredients") }
    var ingredientsSectionSubtitle: String { text("section.ingredients.subtitle", default: "Add one ingredient per row. Amount and unit are optional.") }
    var ingredientNameRequiredHint: String { text("hint.ingredient_name_required", default: "Only the ingredient name is required.") }
    var addIngredient: String { text("action.add_ingredient", default: "Add Ingredient") }
    var editRecipeTitle: String { text("navigation.edit_recipe", default: "Edit Recipe") }
    var newRecipeTitle: String { text("navigation.new_recipe", default: "New Recipe") }
    var saveChanges: String { text("action.save_changes", default: "Save Changes") }
    var save: String { text("action.save", default: "Save") }
    var photoImportFailedTitle: String { text("error.photo_import_failed.title", default: "Photo Import Failed") }
    var editorHeaderSubtitle: String { text("editor.header.subtitle", default: "Name, instructions, and ingredients are the critical fields. Everything else supports search and context.") }
    var photo: String { text("field.photo", default: "Photo") }
    var removePhoto: String { text("action.remove_photo", default: "Remove Photo") }
    var nameField: String { text("field.name", default: "Name") }
    var recipeNamePlaceholder: String { text("placeholder.recipe_name", default: "Recipe name") }
    var keywordsField: String { text("field.keywords", default: "Keywords") }
    var commaSeparatedPlaceholder: String { text("placeholder.comma_separated", default: "comma-separated") }
    var additionalInfoField: String { text("field.additional_info", default: "Additional Info") }
    var additionalInfoPlaceholder: String { text("placeholder.additional_info", default: "Notes, timing, or serving context") }
    var ingredientField: String { text("field.ingredient", default: "Ingredient") }
    var amountField: String { text("field.amount", default: "Amount") }
    var unitField: String { text("field.unit", default: "Unit") }
    var actionsField: String { text("field.actions", default: "Actions") }
    var favoriteBadge: String { text("badge.favorite", default: "Favorite") }
    var scaleIngredients: String { text("action.scale_ingredients", default: "Scale Ingredients") }
    var noPhoto: String { text("placeholder.no_photo", default: "No Photo") }

    func recipeUpdatedMessage(_ name: String) -> (title: String, message: String) {
        (
            text("toast.recipe_updated.title", default: "Recipe Updated"),
            format("toast.recipe_updated.message", default: "\"%@\" is ready.", name)
        )
    }

    func recipeSavedMessage(_ name: String) -> (title: String, message: String) {
        (
            text("toast.recipe_saved.title", default: "Recipe Saved"),
            format("toast.recipe_saved.message", default: "\"%@\" was added to your cookbook.", name)
        )
    }

    func exportCompleteMessage(recipeCount: Int) -> (title: String, message: String) {
        let message: String

        if recipeCount == 1 {
            message = text("toast.export_complete.one", default: "1 recipe exported to JSON.")
        } else {
            message = format("toast.export_complete.many", default: "%lld recipes exported to JSON.", Int64(recipeCount))
        }

        return (text("toast.export_complete.title", default: "Export Complete"), message)
    }

    func deleteRecipeConfirmation(_ name: String) -> String {
        format("confirm.delete_recipe.message", default: "This will permanently remove \"%@\".", name)
    }

    func importCompleteMessage(recipeCount: Int) -> String {
        if recipeCount == 1 {
            return text("toast.import_complete.one", default: "Imported 1 recipe.")
        }

        return format("toast.import_complete.many", default: "Imported %lld recipes.", Int64(recipeCount))
    }

    func recipeDeletedMessage(_ name: String) -> (title: String, message: String) {
        (
            text("toast.recipe_deleted.title", default: "Recipe Deleted"),
            format("toast.recipe_deleted.message", default: "\"%@\" was removed.", name)
        )
    }

    func editorHeaderTitle(isEditing: Bool) -> String {
        isEditing
            ? text("editor.header.title.edit", default: "Refine the recipe details")
            : text("editor.header.title.new", default: "Build a recipe that is easy to scan")
    }

    func choosePhoto(hasPhoto: Bool) -> String {
        hasPhoto
            ? text("action.replace_photo", default: "Replace Photo")
            : text("action.choose_photo", default: "Choose Photo")
    }

    nonisolated static func photoUnreadableErrorText() -> String {
        localizedString(
            "error.photo_unreadable",
            default: "The selected file could not be read as an image.",
            language: resolvedLanguage()
        )
    }

    nonisolated static func photoEncodingErrorText() -> String {
        localizedString(
            "error.photo_encoding",
            default: "The selected image could not be converted into the app's photo format.",
            language: resolvedLanguage()
        )
    }

    var photoUnreadableError: String { Self.photoUnreadableErrorText() }
    var photoEncodingError: String { Self.photoEncodingErrorText() }
}
