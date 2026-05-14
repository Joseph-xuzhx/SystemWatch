import SwiftUI

struct ContentView: View {
    @StateObject private var store = SystemStore()
    @SceneStorage("selectedSection") private var selectedSectionRawValue = MonitorSection.overview.rawValue
    @AppStorage("appLanguage") private var languageRawValue = AppLanguage.chinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    private var selectedSection: Binding<MonitorSection> {
        Binding {
            MonitorSection(rawValue: selectedSectionRawValue) ?? .overview
        } set: { newValue in
            selectedSectionRawValue = newValue.rawValue
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: selectedSection,
                languageRawValue: $languageRawValue,
                refreshInterval: $store.refreshInterval,
                language: language
            )
        } detail: {
            Group {
                switch selectedSection.wrappedValue {
                case .overview:
                    OverviewView(
                        metrics: store.metrics,
                        topProcesses: Array(store.processes.prefix(6)),
                        statusMessage: store.statusMessage,
                        diagnosticMessage: store.diagnosticMessage,
                        history: store.history,
                        language: language
                    )
                case .processes:
                    ProcessesView(store: store, language: language)
                }
            }
            .navigationTitle(selectedSection.wrappedValue.title(language: language))
            .toolbar {
                ToolbarItemGroup {
                    ProgressView()
                        .controlSize(.small)
                        .opacity(store.isRefreshing ? 1 : 0)
                        .frame(width: 18, height: 18)

                    Button {
                        store.refresh()
                    } label: {
                        Label(L10n.text(.refresh, language), systemImage: "arrow.clockwise")
                    }
                    .help(L10n.text(.refresh, language))
                }
            }
        }
        .onAppear {
            store.language = language
            store.start()
        }
        .onDisappear { store.stop() }
        .onChange(of: languageRawValue) { _, _ in
            store.language = language
            store.refresh()
        }
        .onChange(of: store.refreshInterval) { _, newValue in
            store.applyRefreshInterval(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .systemWatchRefreshRequested)) { _ in
            store.refresh()
        }
        .alert(L10n.text(.appName, language), isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK") {
                store.lastError = nil
            }
        } message: {
            Text(store.lastError ?? "")
        }
    }
}
