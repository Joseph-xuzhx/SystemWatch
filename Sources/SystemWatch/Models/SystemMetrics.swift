import Foundation

struct SystemMetrics: Equatable {
    var cpuUsedPercent: Double
    var memoryUsedBytes: Int64
    var memoryTotalBytes: Int64
    var processCount: Int
    var uptimeSeconds: TimeInterval
    var sampledAt: Date

    static let empty = SystemMetrics(
        cpuUsedPercent: 0,
        memoryUsedBytes: 0,
        memoryTotalBytes: 0,
        processCount: 0,
        uptimeSeconds: 0,
        sampledAt: .now
    )

    var memoryUsedPercent: Double {
        guard memoryTotalBytes > 0 else { return 0 }
        return min(100, max(0, Double(memoryUsedBytes) / Double(memoryTotalBytes) * 100))
    }
}
