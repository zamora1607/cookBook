//
//  NewRecipeSheet.swift
//  cookBook
//
//  Created by Codex on 27/03/2026.
//

import SwiftUI

struct NewRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: AppLocalization

    @State private var name: String
    @State private var additionalInfo: String
    @State private var keywords: String
    @State private var photoData: Data?
    @State private var instructionDrafts: [InstructionDraft]
    @State private var ingredientDrafts: [IngredientDraft]
    @State private var isPresentingPhotoImporter = false
    @State private var photoImportErrorMessage: String?
    @FocusState private var focusedInstructionField: InstructionFocusField?
    @FocusState private var focusedIngredientField: IngredientFocusField?

    let recipe: Recipe?
    let onSave: (RecipeFormData) -> Void

    init(recipe: Recipe? = nil, onSave: @escaping (RecipeFormData) -> Void) {
        self.recipe = recipe
        self.onSave = onSave

        _name = State(initialValue: recipe?.name ?? "")
        _additionalInfo = State(initialValue: recipe?.additionalInfo ?? "")
        _keywords = State(initialValue: recipe?.keywords.joined(separator: ", ") ?? "")
        _photoData = State(initialValue: recipe?.photoData)

        let initialInstructions = recipe?.instructionSteps.normalizedInstructionSteps.map(InstructionDraft.init) ?? [InstructionDraft()]
        _instructionDrafts = State(initialValue: initialInstructions.isEmpty ? [InstructionDraft()] : initialInstructions)

        let initialIngredients = recipe?.ingredients.map(IngredientDraft.init) ?? [IngredientDraft()]
        _ingredientDrafts = State(initialValue: initialIngredients.isEmpty ? [IngredientDraft()] : initialIngredients)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !normalizedInstructionSteps.isEmpty
    }

    private var isEditing: Bool {
        recipe != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    editorHeader

                    EditorSection(
                        title: localization.recipeSectionTitle,
                        subtitle: localization.recipeSectionSubtitle
                    ) {
                        recipeSectionContent
                    }

                    EditorSection(
                        title: localization.instructionsSectionTitle,
                        subtitle: localization.instructionsSectionSubtitle
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach($instructionDrafts) { $draft in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(instructionNumber(for: draft.id))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .fill(Color.accentColor)
                                        )
                                        .padding(.top, 4)

                                    TextField(localization.describeStepPlaceholder, text: $draft.text, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(2...4)
                                        .focused($focusedInstructionField, equals: .step(draft.id))
                                        .onSubmit {
                                            handleInstructionSubmit(for: draft.id)
                                        }

                                    Button(role: .destructive) {
                                        removeInstruction(id: draft.id)
                                    } label: {
                                        Image(systemName: "minus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(instructionDrafts.count == 1)
                                    .padding(.top, 6)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.primary.opacity(0.035))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.05))
                                }
                            }

                            HStack(spacing: 12) {
                                Button {
                                    appendInstructionRow()
                                } label: {
                                    Label(localization.addStep, systemImage: "plus.circle")
                                }

                                Button {
                                    focusFirstIngredient()
                                } label: {
                                    Label(localization.jumpToIngredients, systemImage: "arrow.down.circle")
                                }
                            }
                        }
                    }

                    EditorSection(
                        title: localization.ingredientsSectionTitle,
                        subtitle: localization.ingredientsSectionSubtitle
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach($ingredientDrafts) { $draft in
                                VStack(alignment: .leading, spacing: 12) {
                                    ViewThatFits(in: .horizontal) {
                                        HStack(alignment: .top, spacing: 14) {
                                            ingredientFields(for: $draft)
                                        }

                                        VStack(alignment: .leading, spacing: 12) {
                                            ingredientFields(for: $draft)
                                        }
                                    }

                                    Text(localization.ingredientNameRequiredHint)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.primary.opacity(0.035))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.05))
                                }
                            }

                            Button {
                                appendIngredientRow()
                            } label: {
                                Label(localization.addIngredient, systemImage: "plus.circle")
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .navigationTitle(isEditing ? localization.editRecipeTitle : localization.newRecipeTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? localization.saveChanges : localization.save) {
                        saveRecipe()
                    }
                    .disabled(!canSave)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }
        }
        .frame(minWidth: 720, minHeight: 620)
        .fileImporter(
            isPresented: $isPresentingPhotoImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else {
                    return
                }

                photoData = try RecipePhotoProcessor.optimizedJPEGData(from: selectedFile)
            } catch {
                photoImportErrorMessage = error.localizedDescription
            }
        }
        .alert(localization.photoImportFailedTitle, isPresented: photoImportFailedBinding) {
            Button("OK") {
                photoImportErrorMessage = nil
            }
        } message: {
            Text(photoImportErrorMessage ?? localization.unknownError)
        }
    }

    @ViewBuilder
    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.editorHeaderTitle(isEditing: isEditing))
                .font(.title2.weight(.semibold))

            Text(localization.editorHeaderSubtitle)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var recipeSectionContent: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                photoEditorPanel
                    .frame(width: 240)

                recipeMetadataPanel
            }

            VStack(alignment: .leading, spacing: 20) {
                photoEditorPanel
                recipeMetadataPanel
            }
        }
    }

    @ViewBuilder
    private var photoEditorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.photo)
                .font(.caption)
                .foregroundStyle(.secondary)

            RecipePhotoView(
                imageData: photoData,
                width: 220,
                height: 160,
                cornerRadius: 14
            )

            HStack {
                Button(localization.choosePhoto(hasPhoto: photoData != nil)) {
                    isPresentingPhotoImporter = true
                }

                if photoData != nil {
                    Button(localization.removePhoto, role: .destructive) {
                        photoData = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recipeMetadataPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledEditorField(localization.nameField) {
                TextField(localization.recipeNamePlaceholder, text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledEditorField(localization.keywordsField) {
                TextField(localization.commaSeparatedPlaceholder, text: $keywords)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledEditorField(localization.additionalInfoField) {
                TextField(localization.additionalInfoPlaceholder, text: $additionalInfo, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func ingredientFields(for draft: Binding<IngredientDraft>) -> some View {
        LabeledIngredientField(localization.ingredientField) {
            TextField("", text: draft.name)
                .textFieldStyle(.roundedBorder)
                .focused($focusedIngredientField, equals: .name(draft.wrappedValue.id))
                .onSubmit {
                    handleIngredientSubmit(for: draft.wrappedValue.id, field: .name)
                }
        }

        LabeledIngredientField(localization.amountField) {
            TextField("", text: draft.amountText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
                .focused($focusedIngredientField, equals: .amount(draft.wrappedValue.id))
                .onSubmit {
                    handleIngredientSubmit(for: draft.wrappedValue.id, field: .amount)
                }
        }

        LabeledIngredientField(localization.unitField) {
            TextField("", text: draft.unit)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .focused($focusedIngredientField, equals: .unit(draft.wrappedValue.id))
                .onSubmit {
                    handleIngredientSubmit(for: draft.wrappedValue.id, field: .unit)
                }
        }

        VStack(alignment: .leading, spacing: 6) {
            Text(localization.actionsField)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                removeIngredient(id: draft.wrappedValue.id)
            } label: {
                Label(localization.delete, systemImage: "minus.circle")
            }
            .buttonStyle(.borderless)
            .disabled(ingredientDrafts.count == 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func removeIngredient(id: UUID) {
        let removedIndex = ingredientDrafts.firstIndex { $0.id == id }
        ingredientDrafts.removeAll { $0.id == id }

        if ingredientDrafts.isEmpty {
            ingredientDrafts = [IngredientDraft()]
            focusIngredient(.name(ingredientDrafts[0].id))
            return
        }

        guard let removedIndex else {
            return
        }

        let nextIndex = min(removedIndex, ingredientDrafts.count - 1)
        focusIngredient(.name(ingredientDrafts[nextIndex].id))
    }

    private func saveRecipe() {
        let recipe = RecipeFormData(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ingredients: ingredientDrafts.compactMap(\.ingredientData),
            instructionSteps: normalizedInstructionSteps,
            keywords: normalizedKeywords,
            additionalInfo: additionalInfo.cleanedOptionalString,
            photoData: photoData
        )

        onSave(recipe)
        dismiss()
    }

    private func removeInstruction(id: UUID) {
        let removedIndex = instructionDrafts.firstIndex { $0.id == id }
        instructionDrafts.removeAll { $0.id == id }

        if instructionDrafts.isEmpty {
            instructionDrafts = [InstructionDraft()]
            focusInstruction(.step(instructionDrafts[0].id))
            return
        }

        guard let removedIndex else {
            return
        }

        let nextIndex = min(removedIndex, instructionDrafts.count - 1)
        focusInstruction(.step(instructionDrafts[nextIndex].id))
    }

    private func appendInstructionRow() {
        let newDraft = InstructionDraft()
        instructionDrafts.append(newDraft)
        focusInstruction(.step(newDraft.id))
    }

    private func instructionNumber(for id: UUID) -> Int {
        guard let index = instructionDrafts.firstIndex(where: { $0.id == id }) else {
            return 1
        }

        return index + 1
    }

    private func handleInstructionSubmit(for id: UUID) {
        guard let index = instructionDrafts.firstIndex(where: { $0.id == id }) else {
            return
        }

        let stepText = instructionDrafts[index].text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !stepText.isEmpty else {
            if index == instructionDrafts.count - 1 {
                focusFirstIngredient()
            } else {
                focusInstruction(.step(instructionDrafts[index + 1].id))
            }
            return
        }

        if index + 1 < instructionDrafts.count {
            focusInstruction(.step(instructionDrafts[index + 1].id))
            return
        }

        appendInstructionRow()
    }

    private func focusFirstIngredient() {
        guard let firstIngredient = ingredientDrafts.first else {
            return
        }

        DispatchQueue.main.async {
            focusedInstructionField = nil
            focusedIngredientField = .name(firstIngredient.id)
        }
    }

    private func handleIngredientSubmit(for id: UUID, field: IngredientFieldKind) {
        guard let index = ingredientDrafts.firstIndex(where: { $0.id == id }) else {
            return
        }

        let draft = ingredientDrafts[index]
        let hasIngredientName = !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard hasIngredientName else {
            focusIngredient(.name(id))
            return
        }

        switch field {
        case .name:
            let hasDetails = !draft.amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !draft.unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if hasDetails {
                focusIngredient(.amount(id))
            } else {
                appendIngredientRow(after: index)
            }
        case .amount:
            let hasUnit = !draft.unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            if hasUnit {
                focusIngredient(.unit(id))
            } else {
                appendIngredientRow(after: index)
            }
        case .unit:
            appendIngredientRow(after: index)
        }
    }

    private func appendIngredientRow(after index: Int? = nil) {
        let newDraft = IngredientDraft()

        if let index {
            ingredientDrafts.insert(newDraft, at: index + 1)
        } else {
            ingredientDrafts.append(newDraft)
        }

        focusIngredient(.name(newDraft.id))
    }

    private var normalizedKeywords: [String] {
        var seen = Set<String>()

        return keywords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    private var normalizedInstructionSteps: [String] {
        instructionDrafts
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var photoImportFailedBinding: Binding<Bool> {
        Binding(
            get: { photoImportErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    photoImportErrorMessage = nil
                }
            }
        )
    }

    private func focusInstruction(_ field: InstructionFocusField?) {
        DispatchQueue.main.async {
            focusedInstructionField = field
        }
    }

    private func focusIngredient(_ field: IngredientFocusField?) {
        DispatchQueue.main.async {
            focusedIngredientField = field
        }
    }
}

#Preview {
    NewRecipeSheet { _ in }
        .environmentObject(AppLocalization.shared)
}
