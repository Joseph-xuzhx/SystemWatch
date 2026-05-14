import Foundation

struct SystemSnapshot {
    let metrics: SystemMetrics
    let processes: [RunningProcess]
    let warnings: [String]
}
