import SwiftUI

struct TrendChartView: View {
    let title: String
    let samples: [MetricSample]
    let value: (MetricSample) -> Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Canvas { context, size in
                guard samples.count > 1 else {
                    return
                }

                let points = samples.enumerated().map { index, sample in
                    let x = size.width * CGFloat(index) / CGFloat(max(1, samples.count - 1))
                    let y = size.height - size.height * CGFloat(min(100, max(0, value(sample))) / 100)
                    return CGPoint(x: x, y: y)
                }

                var path = Path()
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }

                context.stroke(path, with: .color(.accentColor), lineWidth: 2)
            }
            .frame(height: 92)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
