import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var localization: AppLocalization
    @Binding var searchText: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

                Image(systemName: "book.pages")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text(localization.welcomeTitle)
                    .font(.largeTitle.weight(.semibold))

                Text(localization.welcomeSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(localization.welcomeDescription)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            TextField(localization.searchPrompt, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)
                .onSubmit(onSubmit)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
