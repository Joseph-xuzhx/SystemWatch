import SwiftUI

struct SidebarView: View {
    @Binding var selection: MonitorSection
    @Binding var languageRawValue: String
    @Binding var refreshInterval: RefreshInterval
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 0) {
            List(MonitorSection.allCases, selection: $selection) { section in
                Label(section.title(language: language), systemImage: section.symbolName)
                    .tag(section)
            }
            .listStyle(.sidebar)

            Divider()

            Picker(L10n.text(.refreshRate, language), selection: $refreshInterval) {
                ForEach(RefreshInterval.allCases) { interval in
                    Text(interval.title(language: language))
                        .tag(interval)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)

            Menu {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        languageRawValue = option.rawValue
                    } label: {
                        if option == language {
                            Label(option.displayName, systemImage: "checkmark")
                        } else {
                            Text(option.displayName)
                        }
                    }
                }
            } label: {
                Label("\(L10n.text(.language, language)): \(language.displayName)", systemImage: "globe")
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .help(L10n.text(.language, language))
        }
        .navigationTitle(L10n.text(.appName, language))
        .frame(minWidth: 220)
    }
}
