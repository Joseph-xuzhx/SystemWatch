import SwiftUI

struct ProcessDetailView: View {
    let process: RunningProcess?
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text(.details, language))
                .font(.headline)

            if let process {
                HStack(spacing: 10) {
                    ProcessIconView(process: process)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(process.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(L10n.text(.pid, language)) \(process.pid)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DetailRow(title: L10n.text(.kind, language), value: process.isApplication ? L10n.text(.application, language) : L10n.text(.backgroundProcess, language))
                DetailRow(title: L10n.text(.user, language), value: process.user)
                DetailRow(title: L10n.text(.parentPID, language), value: "\(process.parentPID)")
                DetailRow(title: L10n.text(.state, language), value: localizedState(process.state))
                DetailRow(title: L10n.text(.cpu, language), value: Formatters.percentString(process.cpuPercent))
                DetailRow(title: L10n.text(.memory, language), value: "\(Formatters.memoryString(process.residentBytes)) (\(Formatters.percentString(process.memoryPercent)))")
                DetailRow(title: L10n.text(.started, language), value: process.startDate?.formatted(date: .abbreviated, time: .standard) ?? L10n.text(.unknown, language))
                DetailRow(title: L10n.text(.bundleID, language), value: process.bundleIdentifier ?? L10n.text(.unknown, language))
                DetailRow(title: L10n.text(.path, language), value: process.displayPath)

                if process.isCurrentProcess || process.isCriticalSystemProcess {
                    Label(process.isCurrentProcess ? L10n.text(.currentApp, language) : L10n.text(.protected, language), systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView(
                    L10n.text(.noSelection, language),
                    systemImage: "sidebar.right",
                    description: Text(L10n.text(.noSelectionDescription, language))
                )
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(minWidth: 260, idealWidth: 320, maxWidth: 380, alignment: .topLeading)
        .background(.regularMaterial)
    }

    private func localizedState(_ state: String) -> String {
        switch state {
        case "Idle": L10n.text(.idle, language)
        case "Run": L10n.text(.running, language)
        case "Sleep": L10n.text(.sleeping, language)
        case "Stop": L10n.text(.stopped, language)
        case "Zombie": L10n.text(.zombie, language)
        default: state
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .lineLimit(3)
                .textSelection(.enabled)
        }
    }
}
