import SwiftUI

@main
struct VoiceFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: VoiceFlowModel

    init() {
        let model = VoiceFlowModel()
        _model = State(initialValue: model)
        model.start()
    }

    var body: some Scene {
        MenuBarExtra("Voice Flow", systemImage: model.menuBarSymbolName) {
            MenuBarContentView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
