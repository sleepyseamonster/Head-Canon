import AppKit
import SwiftUI

enum BrandAssets {
    static func logoImage() -> NSImage? {
        if let url = Bundle.main.url(forResource: "HeadCanonLogo", withExtension: "png") {
            return NSImage(contentsOf: url)
        }

        return nil
    }
}

struct AppLogoView: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let logoImage = BrandAssets.logoImage() {
                Image(nsImage: logoImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "waveform")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
