import SwiftUI

@MainActor
struct OnboardingChecklistView: View {
    @Bindable var model: HeadCanonModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setup Checklist")
                .font(.headline)

            ChecklistRow(
                title: "Microphone access",
                state: model.permissionSnapshot.microphone.title,
                detail: SetupBlocker.microphone.detail,
                actionTitle: model.microphoneSetupAction?.title
            ) {
                guard let action = model.microphoneSetupAction else {
                    return
                }

                model.performSetupAction(action)
            }

            ChecklistRow(
                title: "Accessibility access",
                state: model.permissionSnapshot.accessibility.title,
                detail: SetupBlocker.accessibility.detail,
                actionTitle: model.accessibilitySetupAction?.title
            ) {
                guard let action = model.accessibilitySetupAction else {
                    return
                }

                model.performSetupAction(action)
            }

            ChecklistRow(
                title: "OpenAI API key",
                state: model.apiKeyState.title,
                detail: model.apiKeyState.detail,
                actionTitle: model.apiKeyState == .valid ? nil : "Validate"
            ) {
                Task {
                    await model.refreshAPIKeyState()
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}

@MainActor
private struct ChecklistRow: View {
    let title: String
    let state: String
    let detail: String
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(state)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}
