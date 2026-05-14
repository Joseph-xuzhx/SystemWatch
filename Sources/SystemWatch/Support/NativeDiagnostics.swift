import Darwin
import Foundation

enum NativeDiagnostics {
    static func runAndExitIfRequested() {
        if CommandLine.arguments.contains("--diagnose-snapshot") {
            runServiceSnapshotAndExit()
        }

        guard CommandLine.arguments.contains("--diagnose") else {
            return
        }

        print("SystemWatch diagnostics")
        print("processes: \(processCount())")
        print("memory: \(memorySummary())")
        exit(0)
    }

    private static func runServiceSnapshotAndExit() {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let service = SystemMonitorService()
                let first = try await service.fetchSnapshot()
                try await Task.sleep(nanoseconds: 1_100_000_000)
                let second = try await service.fetchSnapshot()
                print("SystemWatch service snapshot diagnostics")
                print("first processes: \(first.processes.count)")
                print("second processes: \(second.processes.count)")
                print("cpu: \(Formatters.percentString(second.metrics.cpuUsedPercent))")
                print("memory: \(Formatters.memoryString(second.metrics.memoryUsedBytes)) / \(Formatters.memoryString(second.metrics.memoryTotalBytes))")
                print("warnings: \(second.warnings.isEmpty ? "none" : second.warnings.joined(separator: " | "))")
                print("top processes:")
                for process in second.processes.prefix(8) {
                    print("  \(process.pid) \(process.name) \(Formatters.memoryString(process.residentBytes)) \(process.command)")
                }
            } catch {
                print("SystemWatch service snapshot diagnostics failed")
                print(error.localizedDescription)
            }

            semaphore.signal()
        }

        if semaphore.wait(timeout: .now() + 12) == .timedOut {
            print("SystemWatch service snapshot diagnostics timed out")
        }

        exit(0)
    }

    private static func processCount() -> Int {
        let byteCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard byteCount > 0 else {
            return 0
        }
        return Int(byteCount) / MemoryLayout<pid_t>.size
    }

    private static func memorySummary() -> String {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return "unavailable"
        }

        let usedPages = Int64(stats.active_count + stats.wire_count + stats.compressor_page_count - stats.speculative_count)
        let usedBytes = usedPages * Int64(vm_kernel_page_size)
        return Formatters.memoryString(usedBytes)
    }
}
