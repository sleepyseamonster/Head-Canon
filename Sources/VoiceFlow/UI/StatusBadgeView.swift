import SwiftUI

struct StatusBadgeView: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.primary.opacity(0.08), in: Capsule())
    }
}
