// BuddyBuilder/Features/Authentication/Views/LocationStepView.swift

import SwiftUI
import CoreLocation

struct LocationStepView: View {
    @ObservedObject var viewModel: UpdatedRegistrationViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showLocationPermissionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top margin for visual breathing room - REDUCED
            Spacer()
                .frame(height: 20)
            
            VStack(spacing: 16) {
                // Manual Location Entry - MOVED TO TOP
                VStack(alignment: .leading, spacing: 8) {
                    Text("registration.step.location.search_title".localized(using: localizationManager))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                        .padding(.leading, 20)
                    
                    LocationSearchField(
                        searchTerm: $viewModel.locationSearchTerm,
                        searchResults: viewModel.locationSearchResults,
                        isSearching: viewModel.isSearchingLocations,
                        placeholder: "registration.step.location.search_placeholder".localized(using: localizationManager),
                        onLocationSelected: { location in
                            // Clear current location when manual location is selected
                            viewModel.clearCurrentLocationSelection()
                            viewModel.selectLocation(location)
                        }
                    )
                    .disabled(viewModel.formData.useCurrentLocation)
                    .opacity(viewModel.formData.useCurrentLocation ? 0.5 : 1.0)
                }
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.formBorder)
                        .frame(height: 1)
                    
                    Text("common.or".localized(using: localizationManager))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(Color.formBorder)
                        .frame(height: 1)
                }
                
                // Current Location Option - MOVED TO BOTTOM
                LocationOptionCard(
                    icon: viewModel.locationPermissionDenied ? "location.slash.fill" : "location.circle.fill",
                    title: viewModel.locationPermissionDenied ?
                        "registration.step.location.permission_denied_title".localized(using: localizationManager) :
                        "registration.step.location.current_location_title".localized(using: localizationManager),
                    subtitle: viewModel.locationPermissionDenied ?
                        "registration.step.location.permission_denied_subtitle".localized(using: localizationManager) :
                        (viewModel.isGettingCurrentLocation ?
                         "registration.step.location.getting_location".localized(using: localizationManager) :
                         "registration.step.location.current_location_subtitle".localized(using: localizationManager)),
                    isSelected: viewModel.formData.useCurrentLocation,
                    isLoading: viewModel.isGettingCurrentLocation,
                    isDisabled: viewModel.locationPermissionDenied
                ) {
                    if viewModel.locationPermissionDenied {
                        showLocationPermissionSheet = true
                    } else if !viewModel.formData.useCurrentLocation {
                        // Clear any existing manual selection first
                        viewModel.formData.selectedLocation = nil
                        viewModel.locationSearchTerm = ""
                        viewModel.requestLocationPermission()
                    } else {
                        // User wants to disable current location
                        viewModel.clearCurrentLocationSelection()
                    }
                }
                
                // Current Selection Display - FIXED: Show immediately when location is detected
                if let selectedLocation = viewModel.formData.selectedLocation {
                    SelectedLocationCard(location: selectedLocation) {
                        viewModel.clearManualLocationSelection()
                    }
                    .environmentObject(localizationManager)
                } else if viewModel.formData.useCurrentLocation && viewModel.hasValidCurrentLocation {
                    CurrentLocationCard(
                        city: viewModel.formData.manualCity,
                        country: viewModel.formData.manualCountry
                    ) {
                        viewModel.clearCurrentLocationSelection()
                    }
                    .environmentObject(localizationManager)
                }
                
                // Error Message
                if viewModel.locationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        
                        Text("registration.step.location.error_message".localized(using: localizationManager))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .sheet(isPresented: $showLocationPermissionSheet) {
            LocationPermissionSheet(
                onEnableLocation: {
                    openAppSettings()
                },
                onContinueManually: {
                    showLocationPermissionSheet = false
                    // Reset permission state to allow manual entry
                    viewModel.locationPermissionDenied = false
                    viewModel.clearCurrentLocationSelection()
                }
            )
            .environmentObject(localizationManager)
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        showLocationPermissionSheet = false
    }
}

// MARK: - Location Permission Banner
struct LocationPermissionBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.slash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Access Needed")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("Tap to enable location or continue manually")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryOrange)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Permission Sheet
struct LocationPermissionSheet: View {
    let onEnableLocation: () -> Void
    let onContinueManually: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primaryOrange.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryOrange)
                }
                
                // Content
                VStack(spacing: 16) {
                    Text("Enable Location Access")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("BuddyBuilder uses your location to help you find sports buddies and events nearby. You can always change this later in Settings.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Enable Location Button
                    Button(action: {
                        onEnableLocation()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                            
                            Text("Open Settings")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.primaryOrange, Color.primaryOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    
                    // Continue Manually Button
                    Button(action: {
                        onContinueManually()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            
                            Text("Enter Location Manually")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primaryOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.primaryOrange, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Location Permission")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        onContinueManually()
                    }
                    .foregroundColor(.secondaryText)
                }
            }
        }
    }
}

// MARK: - Updated Location Option Card (with disabled state)
struct LocationOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    // Convenience initializer for backward compatibility
    init(icon: String, title: String, subtitle: String, isSelected: Bool, isLoading: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.isDisabled = false
        self.action = action
    }
    
    init(icon: String, title: String, subtitle: String, isSelected: Bool, isLoading: Bool, isDisabled: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(cardBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(titleColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected && !isLoading && !isDisabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primaryOrange)
                } else if isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryOrange)
                }
            }
            .padding(16)
            .background(backgroundCardColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected && !isDisabled ? 2 : 1)
            )
            .scaleEffect(isSelected && !isDisabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
    
    private var cardBackgroundColor: Color {
        if isDisabled {
            return Color.orange.opacity(0.2)
        }
        return isSelected ? Color.primaryOrange.opacity(0.2) : Color.formBackground
    }
    
    private var iconColor: Color {
        if isDisabled {
            return .orange
        }
        return isSelected ? .primaryOrange : .secondaryText
    }
    
    private var titleColor: Color {
        if isDisabled {
            return .orange
        }
        return isSelected ? .primaryOrange : .primaryText
    }
    
    private var backgroundCardColor: Color {
        if isDisabled {
            return Color.orange.opacity(0.1)
        }
        return isSelected ? Color.primaryOrange.opacity(0.1) : Color.formBackground
    }
    
    private var borderColor: Color {
        if isDisabled {
            return .orange
        }
        return isSelected ? Color.primaryOrange : Color.formBorder
    }
}

// MARK: - Location Search Field - FIXED: Consistent styling with other cards
struct LocationSearchField: View {
    @Binding var searchTerm: String
    let searchResults: [LocationItem]
    let isSearching: Bool
    let placeholder: String // NEW: Localization support
    let onLocationSelected: (LocationItem) -> Void
    @State private var showDropdown = false
    
    // Convenience initializer for backward compatibility
    init(searchTerm: Binding<String>, searchResults: [LocationItem], isSearching: Bool, onLocationSelected: @escaping (LocationItem) -> Void) {
        self._searchTerm = searchTerm
        self.searchResults = searchResults
        self.isSearching = isSearching
        self.placeholder = "Search city or country"
        self.onLocationSelected = onLocationSelected
    }
    
    // New initializer with placeholder
    init(searchTerm: Binding<String>, searchResults: [LocationItem], isSearching: Bool, placeholder: String, onLocationSelected: @escaping (LocationItem) -> Void) {
        self._searchTerm = searchTerm
        self.searchResults = searchResults
        self.isSearching = isSearching
        self.placeholder = placeholder
        self.onLocationSelected = onLocationSelected
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // Search Input - FIXED: Match card styling (16pt corners like other cards)
                ZStack {
                    RoundedRectangle(cornerRadius: 16) // CHANGED: Back to 16 for consistency with cards
                        .fill(Color.formBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showDropdown ? Color.primaryOrange.opacity(0.5) : Color.formBorder, lineWidth: showDropdown ? 2 : 1)
                        )
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        TextField(placeholder, text: $searchTerm) // CHANGED: Use dynamic placeholder
                            .font(.system(size: 16))
                            .foregroundColor(.primaryText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .onChange(of: searchTerm) { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showDropdown = !searchTerm.isEmpty && searchTerm.count >= 3
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                                .scaleEffect(0.8)
                        } else if !searchTerm.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    searchTerm = ""
                                    showDropdown = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16) // CHANGED: Back to 16 for consistency
                    .padding(.vertical, 14) // CHANGED: Back to 14 for consistency
                }
                .frame(height: 54) // CHANGED: Back to 54 for consistency
            }
            
            // Dropdown Results - Keep overlay positioning
            if showDropdown && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    // Spacer to position dropdown below input
                    Spacer()
                        .frame(height: 60) // Adjusted for new input height
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            ForEach(searchResults) { location in
                                LocationResultRow(location: location) {
                                    onLocationSelected(location)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showDropdown = false
                                    }
                                }
                                
                                if location.id != searchResults.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.formBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16)) // CONSISTENT: Match input corners
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primaryOrange.opacity(0.2), lineWidth: 1)
                    )
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
                .zIndex(1000)
            }
        }
        .onTapGesture {
            // Keep dropdown open when tapping on search field
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDropdown = false
                    }
                }
        )
    }
}

// MARK: - Location Result Row - FIXED: Remove duplicate text
struct LocationResultRow: View {
    let location: LocationItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.primaryOrange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.displayText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    // REMOVED: Duplicate city, country text since displayText already contains it
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Location Card
struct SelectedLocationCard: View {
    let location: LocationItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Location")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Text(location.displayText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 1)
        )
    }
}

// MARK: - Current Location Card
struct CurrentLocationCard: View {
    let city: String
    let country: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Location")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Text("\(city), \(country)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue, lineWidth: 1)
        )
    }
}
