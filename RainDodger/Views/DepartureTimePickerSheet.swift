//
//  DepartureTimePickerSheet.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import SwiftUI

struct DepartureTimePickerSheet: View {
    let viewModel: TripPlannerViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var draftDate: Date
    @State private var timeDraft: Date = Date()
    @State private var isTimeSheetPresented = false

    init(viewModel: TripPlannerViewModel) {
        self.viewModel = viewModel
        _draftDate = State(initialValue: viewModel.departureDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 8)
            DatePicker(
                "Choose departure date",
                selection: $draftDate,
                in: Date()...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Color.checkRouteBlue)
            .accessibilityLabel("Choose departure date")
            .padding(.top, 4)
            timeRow
            leaveNowButton
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isTimeSheetPresented) {
            timeSheet
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(cancelBacking).frame(width: 34, height: 34))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")

            Spacer(minLength: 0)

            Text("Leave at")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button {
                viewModel.setDepartureDate(draftDate)
                dismiss()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.checkRouteBlue).frame(width: 34, height: 34))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apply")
            .accessibilityHint("Apply departure time and re-route")
        }
    }

    private var timeRow: some View {
        HStack(spacing: 12) {
            Text("Time")
                .font(.rdSectionHeader)
                .foregroundStyle(Color.secondary)
            Spacer(minLength: 0)
            Button {
                isTimeSheetPresented = true
            } label: {
                Text(timeText)
                    .font(.rdRowName)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(pillBacking))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time, \(timeText)")
            .accessibilityHint("Double tap to choose the time")
        }
        .padding(.top, 8)
        .frame(minHeight: 44)
    }

    private var leaveNowButton: some View {
        Button {
            viewModel.setDepartureDate(nil)
            dismiss()
        } label: {
            Text("Leave Now")
                .font(.rdRowName)
                .foregroundStyle(Color.blue)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leave now")
        .accessibilityHint("Reset departure to now")
        .padding(.top, 8)
    }

    private var timeSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Time")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button {
                    commitTimeDraft()
                } label: {
                    Text("Done")
                        .font(.rdRowName)
                        .foregroundStyle(Color.blue)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done")
            }
            .padding(.top, 8)
            DatePicker(
                "Choose departure time",
                selection: $timeDraft,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityLabel("Choose departure time")
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
        .presentationDetents([.height(300)])
        .onAppear {
            timeDraft = draftDate
        }
    }

    private func commitTimeDraft() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: draftDate)
        let time = Calendar.current.dateComponents([.hour, .minute], from: timeDraft)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        if let merged = Calendar.current.date(from: components) {
            draftDate = merged
        }
        isTimeSheetPresented = false
    }

    private var timeText: String {
        Self.timeFormatter.string(from: draftDate)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private var cancelBacking: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }

    private var pillBacking: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
}

#Preview {
    DepartureTimePickerSheet(
        viewModel: TripPlannerViewModel(
            directionsService: MockDirectionsService(),
            weatherService: MockWeatherService()
        )
    )
}
