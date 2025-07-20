// BuddyBuilder/Features/Sports/Views/MySportsView.swift

import SwiftUI
import Combine

// MARK: - My Sports View Model
class MySportsViewModel: ObservableObject {
    @Published var userSports: [UserSport] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var showError = false
    @Published var showAddSport = false
    
    private let mySportsService: MySportsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(mySportsService: MySportsServiceProtocol = MySportsService()) {
        self.mySportsService = mySportsService
        loadMySports()
    }
    
    func loadMySports() {
        isLoading = true
        errorMessage = ""
        
        mySportsService.fetchMySports()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to load sports: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] sports in
                    self?.userSports = sports
                    print("✅ Loaded \(sports.count) user sports")
                }
            )
            .store(in: &cancellables)
    }
    
    func removeSport(_ userSport: UserSport) {
        mySportsService.removeSport(userSportId: userSport.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError("Failed to remove sport: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.userSports.removeAll { $0.id == userSport.id }
                        print("✅ Sport removed successfully")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ MySports Error: \(message)")
    }
}

// MARK: - My Sports View
struct MySportsView: View {
    @StateObject private var viewModel = MySportsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LoginBackgroundView()
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Content
                    if viewModel.isLoading && viewModel.userSports.isEmpty {
                        loadingView
                    } else if viewModel.userSports.isEmpty {
                        emptyStateView
                    } else {
                        sportsListView
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primaryOrange.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Title
            Text("My Sports")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Add Button
            Button(action: {
                viewModel.showAddSport = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.primaryOrange)
                    .clipShape(Circle())
                    .shadow(color: .primaryOrange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.9))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryOrange))
                .scaleEffect(1.5)
            
            Text("Loading your sports...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with AsyncImage support
            ZStack {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.primaryOrange.opacity(0.6))
            }
            
            // Text
            VStack(spacing: 12) {
                Text("No Sports Added Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("Add your favorite sports to connect with other players and join events")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 40)
            
            // Add Sport Button
            Button(action: {
                viewModel.showAddSport = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("Add Your First Sport")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.primaryOrange)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .primaryOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sports List View
    private var sportsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.userSports) { userSport in
                    MySportCard(userSport: userSport) {
                        // Remove action
                        viewModel.removeSport(userSport)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            viewModel.loadMySports()
        }
    }
}

// MARK: - My Sport Card
struct MySportCard: View {
    let userSport: UserSport
    let onRemove: () -> Void
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        ZStack {
            // Background Image (API or Default)
            if let iconUrl = userSport.iconUrl, !iconUrl.isEmpty {
                // API Background Image
                AsyncImage(url: URL(string: iconUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // Loading placeholder with default background
                    defaultSportBackground(for: userSport.name)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        )
                }
            } else {
                // Default Sport Background
                defaultSportBackground(for: userSport.name)
            }
            
            // Dark overlay for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content over background
            HStack(spacing: 16) {
                // Sport Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(userSport.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(userSport.userCount) users")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                            .background(
                                BlurView(style: .systemUltraThinMaterialLight)
                                    .clipShape(Capsule()) // Make the blur effect follow the capsule shape
                            )

                    }
                    
                    // Experience Level
                    HStack(spacing: 6) {
                        ForEach(1...4, id: \.self) { level in
                            Circle()
                                .fill(level <= userSport.experienceLevel ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(userSport.experienceLevelName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Description
                    if !userSport.description.isEmpty {
                        Text(userSport.description)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Added date
                    Text("Added \(userSport.formattedAddedDate)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Remove Button
                Button(action: {
                    showRemoveConfirmation = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .background(
                                    BlurView(style: .systemUltraThinMaterialLight)
                                        .clipShape(Capsule()) // Make the blur effect follow the capsule shape
                                )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .confirmationDialog("Remove Sport", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(userSport.name) from your sports?")
        }
    }
    
    // MARK: - Default Sport Background Images
    @ViewBuilder
    private func defaultSportBackground(for sportName: String) -> some View {
        let (colors, pattern) = getSportTheme(for: sportName)
        
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern overlay
            GeometryReader { geometry in
                Path { path in
                    switch pattern {
                    case .basketball:
                        // Basketball lines pattern
                        let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                        let radius = min(geometry.size.width, geometry.size.height) * 0.3
                        
                        // Horizontal line
                        path.move(to: CGPoint(x: center.x - radius, y: center.y))
                        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                        
                        // Vertical line
                        path.move(to: CGPoint(x: center.x, y: center.y - radius))
                        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                        
                    case .tennis:
                        // Tennis net pattern
                        let spacing: CGFloat = 20
                        for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        
                    case .soccer:
                        // Soccer hexagon pattern
                        let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                        let radius: CGFloat = 25
                        for i in 0..<6 {
                            let angle = Double(i) * .pi / 3
                            let point = CGPoint(
                                x: center.x + cos(angle) * radius,
                                y: center.y + sin(angle) * radius
                            )
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                        
                    case .water:
                        // Wave pattern for swimming
                        let waveHeight: CGFloat = 10
                        let waveLength: CGFloat = 40
                        for y in stride(from: waveHeight, to: geometry.size.height, by: 30) {
                            path.move(to: CGPoint(x: 0, y: y))
                            for x in stride(from: 0, to: geometry.size.width, by: waveLength/4) {
                                let controlY = y + (x.truncatingRemainder(dividingBy: waveLength) < waveLength/2 ? -waveHeight : waveHeight)
                                path.addQuadCurve(
                                    to: CGPoint(x: x + waveLength/4, y: y),
                                    control: CGPoint(x: x + waveLength/8, y: controlY)
                                )
                            }
                        }
                        
                    case .track:
                        // Track lanes for running
                        let laneHeight = geometry.size.height / 4
                        for i in 1..<4 {
                            let y = CGFloat(i) * laneHeight
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        
                    case .generic:
                        // Simple geometric pattern
                        let size: CGFloat = 30
                        for x in stride(from: 0, to: geometry.size.width, by: size) {
                            for y in stride(from: 0, to: geometry.size.height, by: size) {
                                path.addRect(CGRect(x: x, y: y, width: size/2, height: size/2))
                            }
                        }
                    }
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
            }
        }
    }
    
    // MARK: - Sport Theme Configuration
    private func getSportTheme(for sportName: String) -> ([Color], PatternType) {
        switch sportName.lowercased() {
        case "basketball":
            return ([.orange, .red.opacity(0.8)], .basketball)
        case "tennis":
            return ([.green, .yellow.opacity(0.8)], .tennis)
        case "soccer", "football":
            return ([.green, .blue.opacity(0.8)], .soccer)
        case "swimming":
            return ([.blue, .cyan.opacity(0.8)], .water)
        case "volleyball":
            return ([.yellow, .orange.opacity(0.8)], .generic)
        case "running", "run":
            return ([.red, .pink.opacity(0.8)], .track)
        case "cycling", "bicycle", "bike":
            return ([.blue, .indigo.opacity(0.8)], .generic)
        case "fitness", "gym":
            return ([.gray, .black.opacity(0.6)], .generic)
        case "golf":
            return ([.green, .mint.opacity(0.8)], .generic)
        case "baseball":
            return ([.brown, .yellow.opacity(0.8)], .generic)
        case "badminton":
            return ([.purple, .pink.opacity(0.8)], .tennis)
        case "boxing":
            return ([.red, .black.opacity(0.8)], .generic)
        case "skiing":
            return ([.white, .blue.opacity(0.6)], .generic)
        case "surfing":
            return ([.blue, .teal.opacity(0.8)], .water)
        case "climbing":
            return ([.brown, .orange.opacity(0.8)], .generic)
        case "wrestling":
            return ([.red, .yellow.opacity(0.8)], .generic)
        case "martial arts", "karate", "judo":
            return ([.black, .red.opacity(0.8)], .generic)
        case "yoga":
            return ([.purple, .pink.opacity(0.8)], .generic)
        case "dance", "dancing":
            return ([.pink, .purple.opacity(0.8)], .generic)
        case "skating", "ice skating":
            return ([.white, .blue.opacity(0.6)], .generic)
        case "hockey":
            return ([.blue, .white.opacity(0.8)], .generic)
        case "archery":
            return ([.brown, .green.opacity(0.8)], .generic)
        case "bowling":
            return ([.purple, .yellow.opacity(0.8)], .generic)
        case "fishing":
            return ([.blue, .green.opacity(0.8)], .water)
        case "hiking":
            return ([.green, .brown.opacity(0.8)], .generic)
        case "sailing":
            return ([.blue, .white.opacity(0.8)], .water)
        case "table tennis", "ping pong":
            return ([.green, .orange.opacity(0.8)], .tennis)
        case "water polo":
            return ([.blue, .yellow.opacity(0.8)], .water)
        case "snowboarding":
            return ([.white, .blue.opacity(0.6)], .generic)
        default:
            return ([.primaryOrange, .primaryOrange.opacity(0.6)], .generic)
        }
    }
}

// MARK: - Pattern Types
enum PatternType {
    case basketball
    case tennis
    case soccer
    case water
    case track
    case generic
}

// MARK: - Blur View Helper
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Preview
#Preview {
    MySportsView()
        .environmentObject(LocalizationManager(localizationService: MockLocalizationService()))
}
