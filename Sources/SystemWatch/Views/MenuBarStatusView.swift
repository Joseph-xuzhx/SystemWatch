import AppKit
import SwiftUI

struct MenuBarStatusLabel: View {
    @StateObject private var store = MenuBarStore()
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        Text(store.statusText)
            .monospacedDigit()
            .onAppear { store.start(language: language) }
            .onDisappear { store.stop() }
            .onChange(of: languageRawValue) { _, _ in
                store.start(language: language)
            }
    }
}

struct MenuBarStatusView: View {
    @StateObject private var store = MenuBarStore()
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text(.menuBarStatus, language))
                .font(.headline)

            Text("CPU \(Formatters.percentString(store.metrics.cpuUsedPercent))")
            Text("\(L10n.text(.memory, language)) \(Formatters.percentString(store.metrics.memoryUsedPercent))")

            Divider()

            Button(L10n.text(.refresh, language)) {
                store.refresh(language: language)
            }

            Button(L10n.text(.showMainWindow, language)) {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }

            Button(L10n.text(.quit, language)) {
                NSApp.terminate(nil)
            }
        }
        .padding(8)
        .frame(width: 220, alignment: .leading)
        .onAppear { store.start(language: language) }
        .onDisappear { store.stop() }
    }
}
