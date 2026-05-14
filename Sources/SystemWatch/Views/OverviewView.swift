import SwiftUI

struct OverviewView: View {
    let metrics: SystemMetrics
    let topProcesses: [RunningProcess]
    let statusMessage: String?
    let diagnosticMessage: String
    let history: [MetricSample]
    let language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let statusMessage, !statusMessage.isEmpty {
                    StatusBanner(message: statusMessage)
                }

                DiagnosticStrip(message: diagnosticMessage)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    MetricGaugeCard(
                        title: L10n.text(.cpu, language),
                        value: metrics.cpuUsedPercent,
                        symbolName: "cpu",
                        detail: Formatters.percentString(metrics.cpuUsedPercent)
                    )

                    MetricGaugeCard(
                        title: L10n.text(.memory, language),
                        value: metrics.memoryUsedPercent,
                        symbolName: "memorychip",
                        detail: "\(Formatters.memoryString(metrics.memoryUsedBytes)) / \(Formatters.memoryString(metrics.memoryTotalBytes))"
                    )

                    MetricSummaryCard(
                        title: L10n.text(.processCount, language),
                        value: "\(metrics.processCount)",
                        symbolName: "app.connected.to.app.below.fill",
                        detail: "\(L10n.text(.updated, language)) \(metrics.sampledAt.formatted(date: .omitted, time: .standard))"
                    )

                    MetricSummaryCard(
                        title: L10n.text(.uptime, language),
                        value: Formatters.uptimeString(metrics.uptimeSeconds),
                        symbolName: "clock.arrow.circlepath",
                        detail: L10n.text(.sinceLastBoot, language)
                    )
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    TrendChartView(
                        title: L10n.text(.cpuHistory, language),
                        samples: history,
                        value: \.cpuPercent
                    )

                    TrendChartView(
                        title: L10n.text(.memoryHistory, language),
                        samples: history,
                        value: \.memoryPercent
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text(.topCPUProcesses, language))
                        .font(.headline)

                    Table(topProcesses) {
                        TableColumn(L10n.text(.name, language)) { process in
                            HStack(spacing: 8) {
                                ProcessIconView(process: process)
                                Text(process.name)
                                    .lineLimit(1)
                            }
                        }
                        TableColumn(L10n.text(.pid, language)) { process in
                            Text("\(process.pid)")
                                .foregroundStyle(.secondary)
                        }
                        TableColumn(L10n.text(.cpu, language)) { process in
                            Text(Formatters.percentString(process.cpuPercent))
                                .monospacedDigit()
                        }
                        TableColumn(L10n.text(.memory, language)) { process in
                            Text(Formatters.memoryString(process.residentBytes))
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 260)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
    }
}

struct DiagnosticStrip: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusBanner: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
                .lineLimit(3)
                .font(.callout)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .foregroundStyle(.secondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MetricGaugeCard: View {
    let title: String
    let value: Double
    let symbolName: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbolName)
                .font(.headline)

            Gauge(value: min(1, max(0, value / 100))) {
                Text(title)
            } currentValueLabel: {
                Text(Formatters.percentString(value))
            }
            .gaugeStyle(.accessoryCircularCapacity)

            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MetricSummaryCard: View {
    let title: String
    let value: String
    let symbolName: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbolName)
                .font(.headline)

            Text(value)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
