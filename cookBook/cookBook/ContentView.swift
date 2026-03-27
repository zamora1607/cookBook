//
//  ContentView.swift
//  cookBook
//
//  Created by Ania on 31/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localization: AppLocalization
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var selectedRecipe: Recipe?
    @State private var activeEditorSession: RecipeEditorSession?
    @State private var isPresentingImporter = false
    @State private var isPresentingExporter = false
    @State private var exportDocument = RecipesExportDocument(recipes: [])
    @State private var importErrorMessage: String?
    @State private var exportErrorMessage: String?
    @State private var recipePendingDeletion: Recipe?
    @State private var feedbackToast: FeedbackToast?

    private var filteredRecipes: [Recipe] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return sortedRecipes(recipes)
        }

        let normalizedQuery = trimmedSearchText.lowercased()

        return sortedRecipes(recipes.filter { recipe in
            recipe.name.localizedStandardContains(trimmedSearchText) ||
            recipe.keywords.contains(where: { $0.localizedStandardContains(normalizedQuery) }) ||
            recipe.ingredients.contains(where: { $0.name.localizedStandardContains(trimmedSearchText) })
        })
    }

    var body: some View {
        NavigationSplitView {
            List(filteredRecipes, selection: $selectedRecipe) { recipe in
                RecipeRowView(recipe: recipe)
                    .tag(recipe)
                    .contextMenu {
                        Button {
                            toggleFavorite(recipe: recipe)
                        } label: {
                            Label(
                                localization.favoriteAction(isFavorite: recipe.isFavorite == true),
                                systemImage: recipe.isFavorite == true ? "heart.slash" : "heart"
                            )
                        }

                        Button {
                            presentEditor(for: recipe)
                        } label: {
                            Label(localization.editRecipe, systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            recipePendingDeletion = recipe
                        } label: {
                            Label(localization.deleteRecipe, systemImage: "trash")
                        }
                    }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
#endif
            .searchable(text: $searchText, prompt: localization.searchPrompt)
            .onDeleteCommand(perform: deleteSelectedRecipe)
        } detail: {
            if let selectedRecipe {
                RecipeDetailView(recipe: selectedRecipe)
            } else if recipes.isEmpty {
                ContentUnavailableView(
                    localization.noRecipesTitle,
                    systemImage: "book.closed",
                    description: Text(localization.noRecipesDescription)
                )
            } else if filteredRecipes.isEmpty {
                ContentUnavailableView(
                    localization.noMatchesTitle,
                    systemImage: "magnifyingglass",
                    description: Text(localization.noMatchesDescription)
                )
            } else {
                ContentUnavailableView(
                    localization.selectRecipeTitle,
                    systemImage: "book.closed",
                    description: Text(localization.selectRecipeDescription)
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let feedbackToast {
                FeedbackToastView(toast: feedbackToast)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker(localization.toolbarLanguage, selection: languageSelection) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(localization.languageName(language))
                                .tag(language)
                        }
                    }
                } label: {
                    Label(localization.toolbarLanguage, systemImage: "globe")
                }
            }

            ToolbarItem {
                Button {
                    isPresentingImporter = true
                } label: {
                    Label(localization.importRecipes, systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            ToolbarItem {
                Button {
                    exportDocument = RecipesExportDocument(recipes: recipes)
                    isPresentingExporter = true
                } label: {
                    Label(localization.exportRecipes, systemImage: "square.and.arrow.up")
                }
                .disabled(recipes.isEmpty)
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            ToolbarItem {
                Button {
                    presentEditor(for: nil)
                } label: {
                    Label(localization.addRecipe, systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            ToolbarItem {
                Button {
                    guard let selectedRecipe else { return }
                    toggleFavorite(recipe: selectedRecipe)
                } label: {
                    Label(
                        localization.favoriteAction(isFavorite: selectedRecipe?.isFavorite == true),
                        systemImage: selectedRecipe?.isFavorite == true ? "heart.fill" : "heart"
                    )
                }
                .disabled(selectedRecipe == nil)
            }

            ToolbarItem {
                Button {
                    presentEditor(for: selectedRecipe)
                } label: {
                    Label(localization.editRecipe, systemImage: "pencil")
                }
                .disabled(selectedRecipe == nil)
                .keyboardShortcut(.return, modifiers: [.command])
            }

            ToolbarItem {
                Button(role: .destructive) {
                    recipePendingDeletion = selectedRecipe
                } label: {
                    Label(localization.deleteRecipe, systemImage: "trash")
                }
                .disabled(selectedRecipe == nil)
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
        .sheet(item: $activeEditorSession) { session in
            NewRecipeSheet(recipe: session.recipe) { formData in
                withAnimation {
                    if let recipe = session.recipe {
                        update(recipe: recipe, with: formData)
                        let message = localization.recipeUpdatedMessage(recipe.name)
                        showToast(
                            title: message.title,
                            message: message.message,
                            systemImage: "checkmark.circle.fill"
                        )
                    } else {
                        createRecipe(from: formData)
                        let message = localization.recipeSavedMessage(formData.name)
                        showToast(
                            title: message.title,
                            message: message.message,
                            systemImage: "checkmark.circle.fill"
                        )
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isPresentingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else {
                    return
                }

                try importRecipes(from: selectedFile)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isPresentingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: localization.exportFilename
        ) { result in
            switch result {
            case .success:
                let message = localization.exportCompleteMessage(recipeCount: recipes.count)
                showToast(
                    title: message.title,
                    message: message.message,
                    systemImage: "square.and.arrow.up.fill"
                )
            case .failure(let error):
                exportErrorMessage = error.localizedDescription
            }
        }
        .alert(localization.exportFailedTitle, isPresented: exportFailedBinding) {
            Button("OK") {
                exportErrorMessage = nil
            }
        } message: {
            Text(exportErrorMessage ?? localization.unknownError)
        }
        .alert(localization.importFailedTitle, isPresented: importFailedBinding) {
            Button("OK") {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? localization.unknownError)
        }
        .alert(localization.deleteRecipeTitle, isPresented: deleteConfirmationBinding, presenting: recipePendingDeletion) { recipe in
            Button(localization.delete, role: .destructive) {
                delete(recipe: recipe)
            }

            Button(localization.cancel, role: .cancel) {
                recipePendingDeletion = nil
            }
        } message: { recipe in
            Text(localization.deleteRecipeConfirmation(recipe.name))
        }
        .onAppear(perform: ensureSelection)
        .onChange(of: searchText) { _, _ in
            ensureSelection()
        }
        .onChange(of: recipes.count) { _, _ in
            ensureSelection()
        }
    }

    private func ensureSelection() {
        guard let selectedRecipe else {
            self.selectedRecipe = filteredRecipes.first
            return
        }

        if !filteredRecipes.contains(selectedRecipe) {
            self.selectedRecipe = filteredRecipes.first
        }
    }

    private func createRecipe(from formData: RecipeFormData) {
        let recipe = Recipe(
            name: formData.name,
            ingredients: formData.ingredients.map(Ingredient.init),
            instructionSteps: formData.instructionSteps,
            keywords: formData.keywords,
            additionalInfo: formData.additionalInfo,
            photoData: formData.photoData
        )

        modelContext.insert(recipe)
        selectedRecipe = recipe
    }

    private func importRecipes(from fileURL: URL) throws {
        let startedAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(RecipesImportPayload.self, from: data)
        let importedRecipes = payload.recipes.map { importedRecipe in
            Recipe(
                name: importedRecipe.name,
                ingredients: importedRecipe.ingredients.map {
                    Ingredient(name: $0.name, amount: $0.amount, unit: $0.unit)
                },
                instructionSteps: importedRecipe.instructionSteps,
                keywords: importedRecipe.keywords,
                additionalInfo: importedRecipe.additionalInfo,
                isFavorite: importedRecipe.isFavorite,
                photoData: importedRecipe.photoData
            )
        }

        guard !importedRecipes.isEmpty else {
            showToast(
                title: localization.importCompleteTitle,
                message: localization.importEmptyMessage,
                systemImage: "square.and.arrow.down.fill"
            )
            return
        }

        for recipe in importedRecipes {
            modelContext.insert(recipe)
        }

        selectedRecipe = importedRecipes.first
        showToast(
            title: localization.importCompleteTitle,
            message: localization.importCompleteMessage(recipeCount: importedRecipes.count),
            systemImage: "square.and.arrow.down.fill"
        )
    }

    private func sortedRecipes(_ recipes: [Recipe]) -> [Recipe] {
        recipes.sorted { lhs, rhs in
            let lhsFavorite = lhs.isFavorite ?? false
            let rhsFavorite = rhs.isFavorite ?? false

            if lhsFavorite != rhsFavorite {
                return lhsFavorite && !rhsFavorite
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func presentEditor(for recipe: Recipe?) {
        activeEditorSession = RecipeEditorSession(recipe: recipe)
    }

    private func update(recipe: Recipe, with formData: RecipeFormData) {
        let previousIngredients = recipe.ingredients

        recipe.name = formData.name
        recipe.instructionSteps = formData.instructionSteps
        recipe.keywords = formData.keywords
        recipe.additionalInfo = formData.additionalInfo
        recipe.photoData = formData.photoData
        recipe.ingredients = formData.ingredients.map(Ingredient.init)

        for ingredient in previousIngredients {
            modelContext.delete(ingredient)
        }

        selectedRecipe = recipe
    }

    private func delete(recipe: Recipe) {
        let deletedRecipeName = recipe.name

        if selectedRecipe == recipe {
            selectedRecipe = nil
        }

        modelContext.delete(recipe)
        recipePendingDeletion = nil

        let message = localization.recipeDeletedMessage(deletedRecipeName)
        showToast(
            title: message.title,
            message: message.message,
            systemImage: "trash.fill"
        )
    }

    private func toggleFavorite(recipe: Recipe) {
        withAnimation {
            recipe.isFavorite = !(recipe.isFavorite ?? false)
        }
    }

    private func deleteSelectedRecipe() {
        guard let selectedRecipe else {
            return
        }

        recipePendingDeletion = selectedRecipe
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { localization.selectedLanguage },
            set: { localization.selectedLanguage = $0 }
        )
    }

    private var exportFailedBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    exportErrorMessage = nil
                }
            }
        )
    }

    private var importFailedBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { recipePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    recipePendingDeletion = nil
                }
            }
        )
    }

    private func showToast(title: String, message: String, systemImage: String) {
        let toast = FeedbackToast(
            title: title,
            message: message,
            systemImage: systemImage
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            feedbackToast = toast
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard feedbackToast?.id == toast.id else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                feedbackToast = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self], inMemory: true)
        .environmentObject(AppLocalization.shared)
}
