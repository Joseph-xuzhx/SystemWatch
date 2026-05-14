import Foundation

struct RunningProcess: Identifiable, Hashable {
    let pid: Int32
    let parentPID: Int32
    let user: String
    let cpuPercent: Double
    let memoryPercent: Double
    let residentBytes: Int64
    let state: String
    let command: String
    let applicationPath: String?
    let bundleIdentifier: String?
    let startDate: Date?
    let isApplication: Bool
    let isCurrentProcess: Bool
    let isCriticalSystemProcess: Bool

    var id: Int32 { pid }

    var name: String {
        let lastPathComponent = URL(fileURLWithPath: command).lastPathComponent
        return lastPathComponent.isEmpty ? command : lastPathComponent
    }

    var displayPath: String {
        command
    }
}
