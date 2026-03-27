import SwiftUI

struct RecipeRowView: View {
    @EnvironmentObject private var localization: AppLocalization
    let recipe: Recipe

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                if !recipe.keywords.isEmpty {
                    RecipeKeywordChipRow(keywords: Array(recipe.keywords.prefix(2)), compact: true)
                }
            }

            Spacer(minLength: 8)

            if recipe.isFavorite == true {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .imageScale(.small)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 5)
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject private var localization: AppLocalization
    let recipe: Recipe
    @State private var selectedScale = ServingsScale.standard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if recipe.photoData != nil {
                    RecipePhotoView(
                        imageData: recipe.photoData,
                        width: nil,
                        height: 260,
                        cornerRadius: 18,
                        showsPlaceholder: false
                    )
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(recipe.name)
                            .font(.largeTitle)
                            .fontWeight(.semibold)

                        if recipe.isFavorite == true {
                            Label(localization.favoriteBadge, systemImage: "heart.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }

                    if !recipe.keywords.isEmpty {
                        RecipeKeywordChipRow(keywords: recipe.keywords)
                    }
                }
                .padding(22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                if !recipe.ingredients.isEmpty {
                    DetailSection {
                        HStack(alignment: .firstTextBaseline) {
                            Text(localization.ingredientsSectionTitle)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Spacer()

                            Text(localization.scaleIngredients)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)

                            Picker(localization.scaleIngredients, selection: $selectedScale) {
                                ForEach(ServingsScale.allCases) { scale in
                                    Text(scale.label).tag(scale)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(width: 260)
                        }

                        ForEach(recipe.ingredients) { ingredient in
                            IngredientDetailRow(
                                ingredient: ingredient,
                                scaleFactor: selectedScale.factor
                            )
                        }
                    }
                }

                DetailSection {
                    Text(localization.instructionsSectionTitle)
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(Array(recipe.instructionSteps.enumerated()), id: \.offset) { index, step in
                        InstructionStepCard(
                            stepNumber: index + 1,
                            text: step
                        )
                    }
                }

                if let additionalInfo = recipe.additionalInfo, !additionalInfo.isEmpty {
                    DetailSection {
                        Text(localization.additionalInfoField)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(additionalInfo)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .onChange(of: recipe.persistentModelID) { _, _ in
            selectedScale = .standard
        }
    }
}

private struct DetailSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct RecipeKeywordChipRow: View {
    let keywords: [String]
    var compact = false

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: compact ? 72 : 96), spacing: compact ? 6 : 8, alignment: .leading)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: compact ? 6 : 8) {
            ForEach(keywords, id: \.self) { keyword in
                Text(keyword)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(compact ? .secondary : .primary)
                    .padding(.horizontal, compact ? 8 : 10)
                    .padding(.vertical, compact ? 4 : 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(compact ? Color.secondary.opacity(0.1) : Color.orange.opacity(0.12))
                    )
            }
        }
    }
}

private struct IngredientDetailRow: View {
    let ingredient: Ingredient
    let scaleFactor: Double

    private var amountText: String? {
        let trimmedAmount = ingredient.scaledAmountText(scaleFactor: scaleFactor)
        let trimmedUnit = ingredient.unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let pieces = [trimmedAmount, trimmedUnit].filter { !$0.isEmpty }

        guard !pieces.isEmpty else {
            return nil
        }

        return pieces.joined(separator: " ")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            if let amountText {
                Text(amountText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)
            } else {
                Color.clear
                    .frame(width: 96, height: 1)
            }

            Text(ingredient.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

private struct InstructionStepCard: View {
    let stepNumber: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(stepNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                )

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
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
}

enum ServingsScale: CaseIterable, Identifiable {
    case oneThird
    case half
    case standard
    case double

    var id: Self { self }

    var factor: Double {
        switch self {
        case .oneThird:
            return 1.0 / 3.0
        case .half:
            return 0.5
        case .standard:
            return 1.0
        case .double:
            return 2.0
        }
    }

    var label: String {
        switch self {
        case .oneThird:
            return "0.33x"
        case .half:
            return "0.5x"
        case .standard:
            return "1x"
        case .double:
            return "2x"
        }
    }
}

extension Ingredient {
    func scaledAmountText(scaleFactor: Double) -> String {
        let scaledAmount = amount * scaleFactor
        return scaledAmount == 0 ? "" : scaledAmount.formatted(.number.precision(.fractionLength(0...2)))
    }

    func description(scaleFactor: Double) -> String {
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountText = scaledAmountText(scaleFactor: scaleFactor)
        let unitText = trimmedUnit.isEmpty ? "" : " \(trimmedUnit)"
        let prefix = "\(amountText)\(unitText)".trimmingCharacters(in: .whitespaces)

        if prefix.isEmpty {
            return name
        }

        return "\(prefix) \(name)"
    }
}
