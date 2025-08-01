// MARK: - Cheap Flights View Model
import SwiftUI
import Combine
import Foundation

// MARK: - Updated Cheap Flights View Model (Navigation to Explore)
class CheapFlightsViewModel: ObservableObject {
    @Published var destinations: [ExploreDestination] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var fromLocationName = "Kochi"
    @Published var fromLocationCode = "COK"
    @Published var currencyInfo: CurrencyDetail?
    
    // ADD: Static cache with currency tracking
    private static var cachedDestinations: [ExploreDestination]? = nil
    private static var lastCachedCurrency: String? = nil
    private static var lastCachedCountry: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let service = ExploreAPIService.shared
    
    // MARK: - Updated fetchCheapFlights with currency cache management
    func fetchCheapFlights() {
        // Check if currency has changed since last cache
        let currentCurrency = CurrencyManager.shared.currencyCode
        let currentCountry = CurrencyManager.shared.countryCode
        
        // First check if we already have cached data AND currency hasn't changed
        if let cachedData = CheapFlightsViewModel.cachedDestinations,
           !cachedData.isEmpty,
           CheapFlightsViewModel.lastCachedCurrency == currentCurrency,
           CheapFlightsViewModel.lastCachedCountry == currentCountry {
            print("✅ Using cached cheap flights data (currency: \(currentCurrency), country: \(currentCountry))")
            self.destinations = cachedData
            self.isLoading = false
            return
        }
        
        // Cache is invalid or currency/country changed, fetch fresh data
        print("🔄 Fetching fresh cheap flights data (currency: \(currentCurrency), country: \(currentCountry))")
        
        isLoading = true
        errorMessage = nil
        
        service.fetchDestinations(departure: fromLocationCode)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] destinations in
                self?.destinations = destinations
                
                // Cache the data with current currency/country info
                CheapFlightsViewModel.cachedDestinations = destinations
                CheapFlightsViewModel.lastCachedCurrency = currentCurrency
                CheapFlightsViewModel.lastCachedCountry = currentCountry
                
                // Update currency info if available
                if let currencyInfo = self?.service.lastFetchedCurrencyInfo {
                    self?.currencyInfo = currencyInfo
                }
                
                print("✅ Cheap flights fetch completed: \(destinations.count) destinations loaded with currency \(currentCurrency)")
            })
            .store(in: &cancellables)
    }
    
    // ADD: Method to clear cache when currency changes
    func clearCache() {
        CheapFlightsViewModel.cachedDestinations = nil
        CheapFlightsViewModel.lastCachedCurrency = nil
        CheapFlightsViewModel.lastCachedCountry = nil
        print("💱 Cleared cheap flights cache and currency tracking")
    }
    
    // NEW: Navigate to explore screen to show cities for a country
    func navigateToExploreCities(countryId: String, countryName: String) {
        SharedSearchDataStore.shared.navigateToExploreCities(
            countryId: countryId,
            countryName: countryName
        )
    }
    
    // UPDATED: Helper method to format price with currency (now uses CurrencyManager)
    func formatPrice(_ price: Int) -> String {
        // Use CurrencyManager for consistent formatting across the app
        return CurrencyManager.shared.formatPrice(price)
    }
}

// MARK: - Updated Dynamic Cheap Flights View (Simplified - No Cities List)
struct DynamicCheapFlights: View {
    @ObservedObject var viewModel: CheapFlightsViewModel
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                // Loading state
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { _ in
                            CheapFlightSkeletonCard()
                        }
                    }
                    .padding(.horizontal)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            } else if let error = viewModel.errorMessage {
                // Error state
                Text("Failed to load destinations: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Countries view - Navigate to explore on tap
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.destinations) { destination in
                            OriginalStyleCheapFlightCard(
                                destination: destination,
                                viewModel: viewModel,
                                imageType: "country"
                            ) {
                                // Navigate to explore screen to show cities
                                viewModel.navigateToExploreCities(
                                    countryId: destination.location.entityId,
                                    countryName: destination.location.name
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .animation(.easeInOut(duration: 0.3), value: viewModel.destinations.count)
            }
        }
        // ADD: Listen for currency changes and refresh data
        .onReceive(NotificationCenter.default.publisher(for: .currencyChanged)) { _ in
            refreshForCurrencyChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: .countryChanged)) { _ in
            refreshForCurrencyChange()
        }
    }
    
    // ADD: Method to handle currency changes
    private func refreshForCurrencyChange() {
        print("💱 Currency changed in CheapFlights - refreshing data")
        viewModel.clearCache()
        viewModel.fetchCheapFlights()
    }
}

// MARK: - Updated Original Style Cheap Flight Card
struct OriginalStyleCheapFlightCard: View {
    let destination: ExploreDestination
    @ObservedObject var viewModel: CheapFlightsViewModel
    let imageType: String // "country" or "city"
    var onTap: (() -> Void)? = nil // Optional tap action
    
    var body: some View {
        Group {
            if let tapAction = onTap {
                Button(action: tapAction) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Dynamic image with FIXED frame and consistent sizing using GenericCachedAsyncImage
            GenericCachedAsyncImage(
                url: URL(string: "https://image.explore.lascadian.com/\(imageType)_\(destination.location.entityId).webp")
            ) { image in
                image
                    .resizable()
                    .scaledToFill() // Changed from scaledToFit to scaledToFill
                    .frame(width: 150, height: 120) // FIXED width and height
                    .clipped() // Clip any overflow
                    .cornerRadius(10)
            } placeholder: {
                // Fallback placeholder with EXACT same frame
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                    
                    VStack(spacing: 4) {
                        Image(systemName: imageType == "city" ? "building.2" : "globe")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Text(String(destination.location.name.prefix(3)).uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .frame(width: 150, height: 120) // EXACT same dimensions
                .cornerRadius(10)
            }
            
            // Text content with fixed width container
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.location.name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                    .lineLimit(1) // Prevent text overflow
                   
                
                Text(destination.is_direct ? "Direct" : "1+stops")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                
                Text(viewModel.formatPrice(destination.price))
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1) // Prevent price overflow
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(width: 150, alignment: .leading) // FIXED width for text container
        }
        .frame(width: 150) // FIXED overall card width
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                .opacity(phase.isIdentity ? 1.0 : 0.8)
        }
    }
}

// MARK: - Updated Skeleton Card (Fixed width)
struct CheapFlightSkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Placeholder image with FIXED dimensions
            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 150, height: 120) // FIXED width and height
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                // Destination name placeholder
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 13)
                    .frame(width: 80)
                    .cornerRadius(4)
                
                // Direct/Connecting placeholder
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 12)
                    .frame(width: 60)
                    .cornerRadius(4)
                
                // Price placeholder
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 20)
                    .frame(width: 70)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(width: 150, alignment: .leading) // FIXED width for text container
        }
        .frame(width: 150) // FIXED overall card width
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                .opacity(phase.isIdentity ? 1.0 : 0.8)
        }
        .opacity(isAnimating ? 0.7 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Updated Original CheapFlights (for backward compatibility)
struct CheapFlights: View {
    var body: some View {
        // This is now replaced by DynamicCheapFlights in the main HomeView
        // Keep this for any other usage
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        Image("cityImage")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New York")
                                .font(.system(size: 13))
                                .foregroundColor(.black)
                                .fontWeight(.medium)
                            Text("Sat, 7 Jun")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .fontWeight(.medium)
                            Text("₹ 2,546")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .scrollTransition { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                    }
                    .containerRelativeFrame(.horizontal)
                }
                .frame(width: 150)
            }
            .padding(.horizontal)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}
