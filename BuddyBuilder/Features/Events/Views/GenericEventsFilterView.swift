// BuddyBuilder/Features/Events/Views/GenericEventsFilterView.swift

import SwiftUI

// MARK: - Generic Events Filter View
struct GenericEventsFilterView<ViewModel: EventsFilterProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    // Local state for managing UI
    @State private var selectedSport: Sport?
    @State private var showCacheOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Cache Strategy Section (sadece CachedEventsViewModel için)
                    if viewModel is CachedEventsViewModel {
                        cacheStrategySection
                    }
                    
                    // Event Type Filter
                    filterSection(title: "Event Type") {
                        eventTypeFilter
                    }
                    
                    // Sport Filter
                    filterSection(title: "Sport") {
                        sportFilter
                    }
                    
                    // Location Filter
                    filterSection(title: "Location") {
                        locationFilter
                    }
                    
                    // Entry Fee Filter
                    filterSection(title: "Max Entry Fee") {
                        entryFeeFilter
                    }
                    
                    // Quick Filters
                    filterSection(title: "Quick Filters") {
                        quickFilters
                    }
                    
                    // Action Buttons
                    actionButtons
                    
                    // Bottom spacing
                    Color.clear.frame(height: 50)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle(viewModel is CachedEventsViewModel ? "Filters & Cache" : "Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Clear All") {
                    clearAllFilters()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Cache Strategy Section (sadece CachedEventsViewModel için)
    @ViewBuilder
    private var cacheStrategySection: some View {
        if let cachedViewModel = viewModel as? CachedEventsViewModel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Cache Strategy")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        showCacheOptions.toggle()
                    }) {
                        Image(systemName: showCacheOptions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryOrange)
                    }
                }
                
                if showCacheOptions {
                    VStack(spacing: 12) {
                        // Cache status
                        cacheStatusCard(for: cachedViewModel)
                        
                        // Cache actions
                        cacheActionsGrid(for: cachedViewModel)
                    }
                    .transition(.opacity.combined(with: .slide))
                    .animation(.easeInOut(duration: 0.3), value: showCacheOptions)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.formBorder, lineWidth: 1)
            )
        }
    }
    
    private func cacheStatusCard(for cachedViewModel: CachedEventsViewModel) -> some View {
        HStack(spacing: 12) {
            // Cache status indicator
            VStack {
                Circle()
                    .fill(cacheStatusColor(for: cachedViewModel))
                    .frame(width: 12, height: 12)
                
                Text("Cache")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cachedViewModel.getCacheInfo())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                
                Text(cacheStatusDescription(for: cachedViewModel))
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if cachedViewModel.hasNewDataAvailable {
                VStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryOrange)
                    
                    Text("New data")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.primaryOrange)
                }
            }
        }
        .padding(12)
        .background(Color.formBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func cacheActionsGrid(for cachedViewModel: CachedEventsViewModel) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            CacheActionButton(
                title: "Load from Cache",
                icon: "externaldrive",
                action: {
                    cachedViewModel.loadEventsFromCache()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            CacheActionButton(
                title: "Force API",
                icon: "arrow.clockwise",
                action: {
                    cachedViewModel.loadEvents(strategy: .apiOnly)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            CacheActionButton(
                title: "Clear Cache",
                icon: "trash",
                isDestructive: true,
                action: {
                    cachedViewModel.clearAllCache()
                    cachedViewModel.loadEvents(strategy: .apiFirst)
                }
            )
            
            CacheActionButton(
                title: "Refresh",
                icon: "arrow.triangle.2.circlepath",
                action: {
                    cachedViewModel.refreshEventsManually()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Helper Methods for Cache
    private func cacheStatusColor(for cachedViewModel: CachedEventsViewModel) -> Color {
        switch cachedViewModel.uiLoadingState {
        case .showingCached:
            return .green
        case .refreshingBackground:
            return .orange
        case .showingSkeleton, .refreshingManual:
            return .red
        case .error:
            return .red
        default:
            return .gray
        }
    }
    
    private func cacheStatusDescription(for cachedViewModel: CachedEventsViewModel) -> String {
        switch cachedViewModel.uiLoadingState {
        case .showingCached:
            return "Data loaded from cache"
        case .refreshingBackground:
            return "Updating in background"
        case .showingSkeleton:
            return "Loading from API"
        case .refreshingManual:
            return "Refreshing data"
        case .error:
            return "Error occurred"
        default:
            return "Cache ready"
        }
    }
    
    // MARK: - Filter Section Helper
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            content()
        }
    }
    
    // MARK: - Event Type Filter
    private var eventTypeFilter: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(EventType.allCases, id: \.self) { eventType in
                Button(action: {
                    if viewModel.selectedEventType == eventType {
                        viewModel.selectedEventType = nil
                    } else {
                        viewModel.selectedEventType = eventType
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: eventTypeIcon(for: eventType))
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(eventType.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(viewModel.selectedEventType == eventType ? .white : .textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(viewModel.selectedEventType == eventType ? Color.primaryOrange : Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.selectedEventType == eventType ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Sport Filter
    private var sportFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected sport display
            if let selectedId = viewModel.selectedSportId {
                HStack {
                    Text("Selected: Sport ID \(selectedId)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryOrange)
                    
                    Spacer()
                    
                    Button("Clear") {
                        viewModel.selectedSportId = nil
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primaryOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Sport selection
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(mockSports, id: \.id) { sport in
                    Button(action: {
                        if viewModel.selectedSportId == sport.id {
                            viewModel.selectedSportId = nil
                        } else {
                            viewModel.selectedSportId = sport.id
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: sportIcon(for: sport.name))
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(sport.name)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .foregroundColor(viewModel.selectedSportId == sport.id ? .white : .textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(viewModel.selectedSportId == sport.id ? Color.primaryOrange : Color.formBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedSportId == sport.id ? Color.primaryOrange : Color.formBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Location Filter
    private var locationFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "location")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                TextField("Enter location...", text: $viewModel.selectedLocation)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                
                if !viewModel.selectedLocation.isEmpty {
                    Button(action: {
                        viewModel.selectedLocation = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.formBorder, lineWidth: 1)
            )
            
            // Popular locations
            Text("Popular locations")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(popularLocations, id: \.self) { location in
                    Button(location) {
                        viewModel.selectedLocation = location
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
        }
    }
    
    // MARK: - Entry Fee Filter
    private var entryFeeFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                TextField("Max fee (e.g., 50)", text: $viewModel.maxEntryFee)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.numberPad)
                
                if !viewModel.maxEntryFee.isEmpty {
                    Button(action: {
                        viewModel.maxEntryFee = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.formBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.formBorder, lineWidth: 1)
            )
            
            // Quick fee options
            Text("Quick options")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(["Free", "10", "25", "50"], id: \.self) { fee in
                    Button(fee == "Free" ? "Free" : "$\(fee)") {
                        viewModel.maxEntryFee = fee == "Free" ? "0" : fee
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Quick Filters
    private var quickFilters: some View {
        VStack(spacing: 12) {
            FilterToggle(
                title: "Upcoming Events Only",
                isOn: $viewModel.showUpcomingOnly
            )
            
            FilterToggle(
                title: "Available Spots Only",
                isOn: $viewModel.showAvailableOnly
            )
            
            FilterToggle(
                title: "Open Registration Only",
                isOn: $viewModel.showOpenRegistrationOnly
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Apply Filters") {
                viewModel.applyFilters()
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.primaryOrange)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            
            Button("Clear All") {
                clearAllFilters()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primaryOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.primaryOrange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Methods
    private func clearAllFilters() {
        viewModel.clearFilters()
    }
    
    private func eventTypeIcon(for eventType: EventType) -> String {
        switch eventType {
        case .normal: return "calendar"
        case .tournament: return "trophy"
        case .featured: return "star"
        }
    }
    
    private func sportIcon(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "basketball": return "basketball"
        case "tennis": return "tennis.racket"
        case "soccer": return "soccer.ball"
        case "swimming": return "figure.pool.swim"
        case "volleyball": return "volleyball"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "fitness": return "dumbbell"
        default: return "figure.run"
        }
    }
    
    // MARK: - Mock Data
    private var mockSports: [Sport] {
        [
            Sport(id: 1, name: "Basketball", description: nil, imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 2, name: "Tennis", description: nil, imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 3, name: "Soccer", description: nil, imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 4, name: "Swimming", description: nil, imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 5, name: "Volleyball", description: nil, imageUrl: nil, defaultEventImageUrl: nil),
            Sport(id: 6, name: "Running", description: nil, imageUrl: nil, defaultEventImageUrl: nil)
        ]
    }
    
    private var popularLocations: [String] {
        ["Baku", "Tbilisi", "Zugdidi", "Sports Center", "City Park", "University"]
    }
}

// MARK: - Preview
#Preview {
    GenericEventsFilterView(viewModel: CachedEventsViewModel())
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
