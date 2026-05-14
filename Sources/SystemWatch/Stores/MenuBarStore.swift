import Foundation

@MainActor
final class MenuBarStore: ObservableObject {
    @Published private(set) var metrics: SystemMetrics = .empty
    @Published private(set) var statusText = "CPU 0% | MEM 0%"

    private let service = SystemMonitorService()
    private var timer: Timer?

    func start(language: AppLanguage) {
        refresh(language: language)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(language: language)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh(language: AppLanguage) {
        Task {
            let snapshot = try? await service.fetchSnapshot()
            if let metrics = snapshot?.metrics {
                self.metrics = metrics
                self.statusText = "CPU \(Formatters.percentString(metrics.cpuUsedPercent)) | MEM \(Formatters.percentString(metrics.memoryUsedPercent))"
            } else {
                self.statusText = L10n.text(.unknown, language)
            }
        }
    }
}
