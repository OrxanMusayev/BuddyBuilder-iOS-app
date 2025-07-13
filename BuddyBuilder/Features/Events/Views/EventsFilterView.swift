import SwiftUI

// MARK: - Events Filter View
struct EventsFilterView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedType: EventType?
    @Binding var selectedSport: Sport?
    @Binding var selectedDate: DateFilter?
    
    let onApply: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Event Type Filter
                        VStack(alignment: .leading, spacing: 16) {
                            Text("events.filter.type".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            eventTypeFilter
                        }
                        
                        // Sport Filter
                        VStack(alignment: .leading, spacing: 16) {
                            Text("events.filter.sport".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            sportFilter
                        }
                        
                        // Date Filter
                        VStack(alignment: .leading, spacing: 16) {
                            Text("events.filter.date".localized(using: localizationManager))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            dateFilter
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .background(Color.formBackground)
                
                // Action Buttons
                actionButtons
            }
            .background(Color.formBackground)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("common.cancel".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text("events.filter.title".localized(using: localizationManager))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Button(action: {
                selectedType = nil
                selectedSport = nil
                selectedDate = nil
            }) {
                Text("events.filter.reset".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryOrange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.formBorder.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Event Type Filter
    private var eventTypeFilter: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(EventType.allCases, id: \.self) { type in
                FilterChip(
                    title: type.rawValue.localized(using: localizationManager),
                    icon: type.icon,
                    isSelected: selectedType == type,
                    onTap: {
                        selectedType = selectedType == type ? nil : type
                    }
                )
            }
        }
    }
    
    // MARK: - Sport Filter
    private var sportFilter: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(Sport.allCases, id: \.self) { sport in
                FilterChip(
                    title: sport.rawValue.localized(using: localizationManager),
                    icon: sport.icon,
                    isSelected: selectedSport == sport,
                    onTap: {
                        selectedSport = selectedSport == sport ? nil : sport
                    }
                )
            }
        }
    }
    
    // MARK: - Date Filter
    private var dateFilter: some View {
        VStack(spacing: 12) {
            ForEach(DateFilter.allCases, id: \.self) { dateFilter in
                FilterOption(
                    title: dateFilter.rawValue.localized(using: localizationManager),
                    isSelected: selectedDate == dateFilter,
                    onTap: {
                        selectedDate = selectedDate == dateFilter ? nil : dateFilter
                    }
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                onApply()
            }) {
                Text("events.filter.apply".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryOrange)
                    )
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("common.cancel".localized(using: localizationManager))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.formBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.formBorder.opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.primaryOrange : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Filter Option
struct FilterOption: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primaryOrange)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    EventsFilterView(
        selectedType: .constant(nil),
        selectedSport: .constant(nil),
        selectedDate: .constant(nil),
        onApply: {}
    )
    .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
