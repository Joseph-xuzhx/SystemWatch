import Combine
import Foundation

@MainActor
final class SystemStore: ObservableObject {
    @Published private(set) var metrics: SystemMetrics = .empty
    @Published private(set) var processes: [RunningProcess] = []
    @Published var selectedProcessIDs: Set<RunningProcess.ID> = []
    @Published var searchText = ""
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var statusMessage: String?
    @Published var diagnosticMessage = ""
    @Published var processSort: ProcessSort = .cpu
    @Published var processFilter: ProcessFilter = .all
    @Published var refreshInterval: RefreshInterval = .threeSeconds
    @Published private(set) var history: [MetricSample] = []
    var language: AppLanguage = .chinese {
        didSet {
            if diagnosticMessage.isEmpty || diagnosticMessage == L10n.text(.waitingFirstRefresh, oldValue) {
                diagnosticMessage = L10n.text(.waitingFirstRefresh, language)
            }
        }
    }

    private let service = SystemMonitorService()
    private var timer: Timer?
    private let currentUser = NSUserName()

    var filteredProcesses: [RunningProcess] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = processes.filter { process in
            let matchesFilter: Bool
            switch processFilter {
            case .all:
                matchesFilter = true
            case .currentUser:
                matchesFilter = process.user == currentUser
            case .applications:
                matchesFilter = process.isApplication
            case .background:
                matchesFilter = !process.isApplication
            }

            guard matchesFilter else {
                return false
            }

            guard !trimmedSearch.isEmpty else {
                return true
            }

            return process.name.localizedCaseInsensitiveContains(trimmedSearch)
                || process.command.localizedCaseInsensitiveContains(trimmedSearch)
                || String(process.pid).contains(trimmedSearch)
                || process.user.localizedCaseInsensitiveContains(trimmedSearch)
        }

        return filtered.sorted { lhs, rhs in
            switch processSort {
            case .cpu:
                if lhs.cpuPercent == rhs.cpuPercent { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                return lhs.cpuPercent > rhs.cpuPercent
            case .memory:
                if lhs.residentBytes == rhs.residentBytes { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                return lhs.residentBytes > rhs.residentBytes
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .pid:
                return lhs.pid < rhs.pid
            case .user:
                if lhs.user == rhs.user { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                return lhs.user.localizedCaseInsensitiveCompare(rhs.user) == .orderedAscending
            }
        }
    }

    var selectedProcess: RunningProcess? {
        guard let selectedID = selectedProcessIDs.first else {
            return nil
        }
        return processes.first { $0.id == selectedID }
    }

    func start() {
        diagnosticMessage = L10n.text(.waitingFirstRefresh, language)
        refresh()
        restartTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task {
            do {
                let snapshot = try await service.fetchSnapshot()
                metrics = snapshot.metrics
                processes = snapshot.processes
                appendHistory(from: snapshot.metrics)
                selectedProcessIDs = selectedProcessIDs.intersection(Set(snapshot.processes.map(\.id)))
                lastError = nil
                diagnosticMessage = String(
                    format: L10n.text(.lastRefresh, language),
                    snapshot.processes.count,
                    Formatters.percentString(snapshot.metrics.cpuUsedPercent),
                    Formatters.memoryString(snapshot.metrics.memoryUsedBytes),
                    snapshot.metrics.sampledAt.formatted(date: .omitted, time: .standard)
                )
                if snapshot.processes.isEmpty {
                    statusMessage = L10n.text(.zeroProcessSnapshot, language)
                } else {
                    statusMessage = snapshot.warnings.isEmpty ? nil : snapshot.warnings.joined(separator: "\n")
                }
                log(diagnosticMessage)
                if let statusMessage {
                    log(String(format: L10n.text(.status, language), statusMessage))
                }
            } catch {
                lastError = error.localizedDescription
                statusMessage = error.localizedDescription
                diagnosticMessage = String(format: L10n.text(.refreshFailed, language), error.localizedDescription)
                log(diagnosticMessage)
            }

            isRefreshing = false
        }
    }

    func terminateSelected(force: Bool) {
        let ids = selectedProcessIDs.filter { pid in
            guard let process = processes.first(where: { $0.id == pid }) else {
                return false
            }
            return !process.isCurrentProcess && !process.isCriticalSystemProcess
        }
        terminate(pids: Array(ids), force: force)
    }

    func terminate(process: RunningProcess, force: Bool) {
        guard !process.isCurrentProcess, !process.isCriticalSystemProcess else {
            return
        }

        selectedProcessIDs = [process.id]
        terminate(pids: [process.id], force: force)
    }

    func terminate(processIDs: Set<RunningProcess.ID>, force: Bool) {
        selectedProcessIDs = processIDs
        let ids = processIDs.filter { pid in
            guard let process = processes.first(where: { $0.id == pid }) else {
                return false
            }
            return !process.isCurrentProcess && !process.isCriticalSystemProcess
        }
        terminate(pids: Array(ids), force: force)
    }

    private func terminate(pids ids: [RunningProcess.ID], force: Bool) {
        guard !ids.isEmpty else { return }

        Task {
            var failures: [String] = []

            for pid in ids {
                do {
                    try await service.terminate(pid: pid, force: force)
                } catch {
                    failures.append(error.localizedDescription)
                }
            }

            if failures.isEmpty {
                selectedProcessIDs.removeAll()
                lastError = nil
            } else {
                lastError = failures.joined(separator: "\n")
            }

            refresh()
        }
    }

    func applyRefreshInterval(_ interval: RefreshInterval) {
        refreshInterval = interval
        restartTimer()
        if interval != .paused {
            refresh()
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = nil

        guard let seconds = refreshInterval.seconds else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func appendHistory(from metrics: SystemMetrics) {
        history.append(MetricSample(
            date: metrics.sampledAt,
            cpuPercent: metrics.cpuUsedPercent,
            memoryPercent: metrics.memoryUsedPercent
        ))

        if history.count > 60 {
            history.removeFirst(history.count - 60)
        }
    }

    private func log(_ message: String) {
        let line = "[SystemWatch] \(message)\n"
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
