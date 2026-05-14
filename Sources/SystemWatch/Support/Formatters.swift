import Foundation

enum Formatters {
    static let memory: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let time: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func memoryString(_ bytes: Int64) -> String {
        memory.string(fromByteCount: bytes)
    }

    static func percentString(_ value: Double) -> String {
        "\(percent.string(from: NSNumber(value: value)) ?? "0")%"
    }

    static func uptimeString(_ seconds: TimeInterval) -> String {
        time.string(from: seconds) ?? "0m"
    }
}
