import SwiftUI

struct ProcessesView: View {
    @ObservedObject var store: SystemStore
    let language: AppLanguage
    @State private var isShowingTerminateConfirmation = false
    @State private var forceTerminate = false

    private var terminateTitle: String {
        let count = terminableProcesses.count
        if count == 1 {
            return L10n.text(.endProcess, language)
        }
        return String(format: L10n.text(.endProcesses, language), count)
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                if let statusMessage = store.statusMessage, !statusMessage.isEmpty {
                    StatusBanner(message: statusMessage)
                        .padding([.horizontal, .top], 12)
                        .padding(.bottom, 8)
                }

                HStack(spacing: 10) {
                    Picker(L10n.text(.filter, language), selection: $store.processFilter) {
                        ForEach(ProcessFilter.allCases) { filter in
                            Text(filter.title(language: language)).tag(filter)
                        }
                    }
                    .frame(width: 180)

                    Picker(L10n.text(.sortBy, language), selection: $store.processSort) {
                        ForEach(ProcessSort.allCases) { sort in
                            Text(sort.title(language: language)).tag(sort)
                        }
                    }
                    .frame(width: 160)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                DiagnosticStrip(message: store.diagnosticMessage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                if store.filteredProcesses.isEmpty {
                    ContentUnavailableView(
                        store.searchText.isEmpty ? L10n.text(.noProcesses, language) : L10n.text(.noMatches, language),
                        systemImage: "list.bullet.rectangle",
                        description: Text(store.searchText.isEmpty ? L10n.text(.noProcessesDescription, language) : L10n.text(.noMatchesDescription, language))
                    )
                } else {
                    ProcessListView(
                        processes: store.filteredProcesses,
                        selectedProcessIDs: $store.selectedProcessIDs,
                        language: language,
                        terminate: { process, force in
                            store.terminate(process: process, force: force)
                        }
                    )
                }
            }

            ProcessDetailView(process: store.selectedProcess, language: language)
        }
        .searchable(text: $store.searchText, prompt: Text(L10n.text(.searchPrompt, language)))
        .toolbar {
            ToolbarItemGroup {
                Button {
                    forceTerminate = false
                    isShowingTerminateConfirmation = true
                } label: {
                    Label(L10n.text(.end, language), systemImage: "xmark.circle")
                }
                .help(L10n.text(.endSelectedProcess, language))
                .disabled(!canTerminateSelection)

                Menu {
                    Button(L10n.text(.forceQuit, language)) {
                        forceTerminate = true
                        isShowingTerminateConfirmation = true
                    }
                    .disabled(!canTerminateSelection)
                } label: {
                    Label(L10n.text(.more, language), systemImage: "ellipsis.circle")
                }
                .help(L10n.text(.moreProcessActions, language))
            }
        }
        .confirmationDialog(
            terminateTitle,
            isPresented: $isShowingTerminateConfirmation,
            titleVisibility: .visible
        ) {
            Button(forceTerminate ? L10n.text(.forceQuit, language) : L10n.text(.end, language), role: .destructive) {
                store.terminateSelected(force: forceTerminate)
            }
            Button(L10n.text(.cancel, language), role: .cancel) {}
        } message: {
            Text(terminateMessage)
        }
    }

    private var canTerminateSelection: Bool {
        !terminableProcesses.isEmpty
    }

    private func canTerminate(_ process: RunningProcess) -> Bool {
        !process.isCurrentProcess && !process.isCriticalSystemProcess
    }

    private func canTerminate(_ selection: Set<RunningProcess.ID>) -> Bool {
        selection.contains { pid in
            guard let process = store.processes.first(where: { $0.id == pid }) else {
                return false
            }
            return canTerminate(process)
        }
    }

    private var terminableProcesses: [RunningProcess] {
        store.selectedProcessIDs.compactMap { pid in
            guard let process = store.processes.first(where: { $0.id == pid }) else {
                return nil
            }
            return process.isCurrentProcess || process.isCriticalSystemProcess ? nil : process
        }
    }

    private var terminateMessage: String {
        let targets = terminableProcesses
            .prefix(5)
            .map { "\($0.name) (\(L10n.text(.pid, language)) \($0.pid))" }
            .joined(separator: "\n")
        let suffix = terminableProcesses.count > 5 ? "\n..." : ""
        return "\(targets)\(suffix)\n\n\(L10n.text(.protectedProcessWarning, language))"
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

private struct ProcessListView: View {
    let processes: [RunningProcess]
    @Binding var selectedProcessIDs: Set<RunningProcess.ID>
    let language: AppLanguage
    let terminate: (RunningProcess, Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProcessHeader(language: language)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(processes) { process in
                        ProcessRow(
                            process: process,
                            isSelected: selectedProcessIDs.contains(process.id),
                            language: language,
                            select: {
                                selectedProcessIDs = [process.id]
                            },
                            terminate: terminate
                        )
                    }
                }
            }
        }
    }
}

private struct ProcessHeader: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Text(L10n.text(.name, language)).frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
            Text(L10n.text(.pid, language)).frame(width: 74, alignment: .trailing)
            Text(L10n.text(.user, language)).frame(width: 110, alignment: .leading)
            Text(L10n.text(.cpu, language)).frame(width: 82, alignment: .trailing)
            Text(L10n.text(.memory, language)).frame(width: 120, alignment: .trailing)
            Text(L10n.text(.state, language)).frame(width: 82, alignment: .leading)
            Text(L10n.text(.command, language)).frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial)
    }
}

private struct ProcessRow: View {
    let process: RunningProcess
    let isSelected: Bool
    let language: AppLanguage
    let select: () -> Void
    let terminate: (RunningProcess, Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ProcessIconView(process: process)
                Text(process.name).lineLimit(1)
            }
            .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            Text("\(process.pid)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 74, alignment: .trailing)

            Text(process.user)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)

            Text(Formatters.percentString(process.cpuPercent))
                .monospacedDigit()
                .frame(width: 82, alignment: .trailing)

            Text(Formatters.memoryString(process.residentBytes))
                .monospacedDigit()
                .frame(width: 120, alignment: .trailing)

            Text(localizedState(process.state))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 82, alignment: .leading)

            Text(process.command)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .overlay {
            RightClickSelectionView(
                select: select,
                endTitle: L10n.text(.end, language),
                forceQuitTitle: L10n.text(.forceQuit, language),
                canTerminate: canTerminate,
                end: {
                    terminate(process, false)
                },
                forceQuit: {
                    terminate(process, true)
                }
            )
        }
        .onTapGesture {
            select()
        }
    }

    private var canTerminate: Bool {
        !process.isCurrentProcess && !process.isCriticalSystemProcess
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
