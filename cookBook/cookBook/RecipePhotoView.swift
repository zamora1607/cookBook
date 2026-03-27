import SwiftUI
#if canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#endif

struct RecipePhotoView: View {
    @EnvironmentObject private var localization: AppLocalization
    let imageData: Data?
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    var showsPlaceholder = true

    var body: some View {
        if let image = renderedImage {
            container {
                image
                    .resizable()
                    .scaledToFill()
            }
        } else if showsPlaceholder {
            container {
                ZStack {
                    LinearGradient(
                        colors: [Color.orange.opacity(0.18), Color.red.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Text(localization.noPhoto)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func container<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if let width {
            content()
                .frame(width: width, height: height)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
        } else {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
        }
    }

    private var renderedImage: Image? {
        guard let imageData, let platformImage = PlatformImage(data: imageData) else {
            return nil
        }

#if canImport(AppKit)
        return Image(nsImage: platformImage)
#elseif canImport(UIKit)
        return Image(uiImage: platformImage)
#else
        return nil
#endif
    }
}
