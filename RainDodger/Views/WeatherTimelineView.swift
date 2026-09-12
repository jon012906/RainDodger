import SwiftUI

struct WeatherTimelineView: View {
    let stepWeathers: [RouteStepWeather]
    let overallRisk: RainRisk

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(transitions, id: \.stepIndex) { entry in
                        timelineRow(entry)
                        if entry.stepIndex != transitions.last?.stepIndex {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Along Route")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(overallRiskSummary)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            riskBadge(overallRisk)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var overallRiskSummary: String {
        switch overallRisk {
        case .low:
            return "No significant rain expected"
        case .moderate:
            return "Possible rain along the route"
        case .high:
            return "Rain expected along your route"
        case .veryHigh:
            return "Heavy rain expected along your route"
        }
    }

    private func timelineRow(_ entry: RouteStepWeather) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.arrivalDate, style: .time)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                if !entry.roadName.isEmpty {
                    Text(entry.roadName)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 70, alignment: .leading)

            Circle()
                .fill(entry.rainRisk.color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: entry.rainRisk.icon)
                        .font(.caption)
                        .foregroundStyle(entry.rainRisk.color)
                    Text(entry.rainRisk.label)
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                }
                Text("\(Int(entry.rainChance * 100))% precipitation")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(entry.instruction)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var transitions: [RouteStepWeather] {
        var result: [RouteStepWeather] = []
        var lastRisk: RainRisk?
        for entry in stepWeathers {
            if entry.rainRisk != lastRisk || result.isEmpty {
                result.append(entry)
                lastRisk = entry.rainRisk
            }
        }
        return result
    }

    private func riskBadge(_ risk: RainRisk) -> some View {
        HStack(spacing: 4) {
            Image(systemName: risk.icon)
                .font(.caption)
            Text(risk.label)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(risk.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(risk.color.opacity(0.15))
        )
    }
}

extension RainRisk {
    var color: Color {
        switch self {
        case .low: .blue
        case .moderate: .yellow
        case .high: .orange
        case .veryHigh: .red
        }
    }
}

#Preview {
    WeatherTimelineView(
        stepWeathers: [
            RouteStepWeather(
                stepIndex: 0,
                instruction: "Head north on Main Street",
                distanceFromStart: 0,
                arrivalDate: Date(),
                rainChance: 0.1,
                precipitationAmount: 0,
                condition: .clear,
                rainRisk: .low,
                roadName: "Main Street"
            ),
            RouteStepWeather(
                stepIndex: 1,
                instruction: "Turn right onto Highway 101",
                distanceFromStart: 5000,
                arrivalDate: Date().addingTimeInterval(300),
                rainChance: 0.75,
                precipitationAmount: 5,
                condition: .rain,
                rainRisk: .high,
                roadName: "Highway 101"
            ),
            RouteStepWeather(
                stepIndex: 2,
                instruction: "Continue on Highway 101",
                distanceFromStart: 15000,
                arrivalDate: Date().addingTimeInterval(900),
                rainChance: 0.85,
                precipitationAmount: 8,
                condition: .heavyRain,
                rainRisk: .veryHigh,
                roadName: "Highway 101"
            ),
            RouteStepWeather(
                stepIndex: 3,
                instruction: "Arrive at destination",
                distanceFromStart: 25000,
                arrivalDate: Date().addingTimeInterval(1500),
                rainChance: 0.2,
                precipitationAmount: 0.5,
                condition: .cloudy,
                rainRisk: .low,
                roadName: ""
            )
        ],
        overallRisk: .high
    )
    .frame(width: 340)
    .padding()
}
