import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct SystemWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        NativeDiagnostics.runAndExitIfRequested()
    }

    var body: some Scene {
        WindowGroup("SystemWatch", id: "main") {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            SystemWatchCommands()
        }

        MenuBarExtra {
            MenuBarStatusView()
        } label: {
            MenuBarStatusLabel()
        }
    }
}

extension Notification.Name {
    static let systemWatchRefreshRequested = Notification.Name("systemWatchRefreshRequested")
}

struct SystemWatchCommands: Commands {
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button(L10n.text(.refresh, language)) {
                NotificationCenter.default.post(name: .systemWatchRefreshRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
    }
}
