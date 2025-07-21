import Foundation
import SwiftUI
import UIKit
import SwiftUICore
import Combine

// MARK: - Enhanced Recent Search Data Model
struct RecentSearchItem: Identifiable, Codable {
    var id = UUID()
    let fromLocation: String
    let toLocation: String
    let fromIataCode: String
    let toIataCode: String
    
    // ENHANCED: Store detailed passenger information
    let adultsCount: Int
    let childrenCount: Int
    let childrenAges: [Int?] // Store children ages
    
    let cabinClass: String
    let searchDate: Date
    
    // ENHANCED: Store trip type information
    let isRoundTrip: Bool
    let selectedTab: Int // 0: Return, 1: One way, 2: Multi city
    
    // ENHANCED: Store date information if available
    let departureDate: Date?
    let returnDate: Date?
    
    var displayRoute: String {
        return "\(fromIataCode) - \(toIataCode)"
    }
    
    var passengerInfo: String {
        let totalPassengers = adultsCount + childrenCount
        return "\(totalPassengers) \(totalPassengers == 1 ? "Person" : "People")"
    }
    
    var detailedPassengerInfo: String {
        if childrenCount > 0 {
            return "\(adultsCount) Adult\(adultsCount > 1 ? "s" : ""), \(childrenCount) Child\(childrenCount > 1 ? "ren" : "")"
        } else {
            return "\(adultsCount) Adult\(adultsCount > 1 ? "s" : "")"
        }
    }
}

// MARK: - Enhanced Recent Search Manager
class RecentSearchManager: ObservableObject {
    @Published var recentSearches: [RecentSearchItem] = []
    private let maxRecentSearches = 5
    private let userDefaultsKey = "RecentSearches"
    
    // Singleton instance to ensure consistency across the app
    static let shared = RecentSearchManager()
    
    private init() {
        loadRecentSearches()
    }
    
    // ENHANCED: Add a new search to recent searches with complete information
    func addRecentSearch(
        fromLocation: String,
        toLocation: String,
        fromIataCode: String,
        toIataCode: String,
        adultsCount: Int,
        childrenCount: Int,
        childrenAges: [Int?] = [],
        cabinClass: String,
        isRoundTrip: Bool = true,
        selectedTab: Int = 0,
        departureDate: Date? = nil,
        returnDate: Date? = nil
    ) {
        // Don't add if either location is empty or placeholder
        guard !fromIataCode.isEmpty && !toIataCode.isEmpty &&
              fromLocation != "Departure?" && toLocation != "Destination?" &&
              fromLocation != "Where from?" && toLocation != "Where to?" else {
            return
        }
        
        let newSearch = RecentSearchItem(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: childrenAges,
            cabinClass: cabinClass,
            searchDate: Date(),
            isRoundTrip: isRoundTrip,
            selectedTab: selectedTab,
            departureDate: departureDate,
            returnDate: returnDate
        )
        
        // Remove existing search with same route to avoid duplicates
        recentSearches.removeAll { existing in
            existing.fromIataCode == newSearch.fromIataCode &&
            existing.toIataCode == newSearch.toIataCode
        }
        
        // Add new search at the beginning
        recentSearches.insert(newSearch, at: 0)
        
        // Keep only the most recent searches
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    // LEGACY: Keep the old method for backward compatibility
    func addRecentSearch(
        fromLocation: String,
        toLocation: String,
        fromIataCode: String,
        toIataCode: String,
        adultsCount: Int,
        childrenCount: Int,
        cabinClass: String
    ) {
        // Call the enhanced method with default values
        addRecentSearch(
            fromLocation: fromLocation,
            toLocation: toLocation,
            fromIataCode: fromIataCode,
            toIataCode: toIataCode,
            adultsCount: adultsCount,
            childrenCount: childrenCount,
            childrenAges: Array(repeating: nil, count: childrenCount),
            cabinClass: cabinClass,
            isRoundTrip: true,
            selectedTab: 0,
            departureDate: nil,
            returnDate: nil
        )
    }
    
    // Clear all recent searches
    func clearAllRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    // ENHANCED: Apply a recent search with complete data reconstruction
    func applyRecentSearch(_ search: RecentSearchItem, to viewModel: SharedFlightSearchViewModel) {
        // Apply basic search parameters
        viewModel.fromLocation = search.fromLocation
        viewModel.toLocation = search.toLocation
        viewModel.fromIataCode = search.fromIataCode
        viewModel.toIataCode = search.toIataCode
        viewModel.selectedCabinClass = search.cabinClass
        
        // ENHANCED: Apply detailed passenger information
        viewModel.adultsCount = search.adultsCount
        viewModel.childrenCount = search.childrenCount
        
        // Handle children ages properly
        if search.childrenCount > 0 {
            if search.childrenAges.count == search.childrenCount {
                viewModel.childrenAges = search.childrenAges
            } else {
                // Fallback: create array with nil ages
                viewModel.childrenAges = Array(repeating: nil, count: search.childrenCount)
            }
        } else {
            viewModel.childrenAges = []
        }
        
        // ENHANCED: Apply trip type information
        viewModel.isRoundTrip = search.isRoundTrip
        viewModel.selectedTab = search.selectedTab
        
        // ENHANCED: Set appropriate dates
        setIntelligentDatesAndExecuteSearch(for: viewModel, basedOn: search)
    }
    
    // ENHANCED: Helper method to set intelligent dates and execute search
    private func setIntelligentDatesAndExecuteSearch(for viewModel: SharedFlightSearchViewModel, basedOn search: RecentSearchItem) {
        let calendar = Calendar.current
        let today = Date()
        
        var departureDate: Date
        var returnDate: Date?
        
        // Use stored dates if available and still valid (in the future)
        if let storedDeparture = search.departureDate, storedDeparture > today {
            departureDate = storedDeparture
            
            if search.isRoundTrip, let storedReturn = search.returnDate, storedReturn > storedDeparture {
                returnDate = storedReturn
            } else if search.isRoundTrip {
                // Create return date based on departure
                returnDate = calendar.date(byAdding: .day, value: 7, to: departureDate)
            }
        } else {
            // Create new appropriate dates
            departureDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            
            if search.isRoundTrip {
                returnDate = calendar.date(byAdding: .day, value: 7, to: departureDate) ?? departureDate
            }
        }
        
        // Update the view model dates
        if search.isRoundTrip && returnDate != nil {
            viewModel.selectedDates = [departureDate, returnDate!]
        } else {
            viewModel.selectedDates = [departureDate]
        }
        
        // ENHANCED: Execute search automatically with proper delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.executeSearch()
        }
        
        print("✅ Enhanced recent search applied and search executed automatically")
        print("🔍 Route: \(viewModel.fromIataCode) → \(viewModel.toIataCode)")
        print("👥 Passengers: \(viewModel.adultsCount) adults, \(viewModel.childrenCount) children")
        print("✈️ Trip Type: \(search.isRoundTrip ? "Round Trip" : "One Way")")
        print("🏷️ Class: \(search.cabinClass)")
        
        // Format dates for logging
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let departureDateString = formatter.string(from: departureDate)
        let returnDateString = returnDate != nil ? formatter.string(from: returnDate!) : "N/A"
        print("📅 Dates: \(departureDateString) - \(returnDateString)")
    }
    
    // Save to UserDefaults
    private func saveRecentSearches() {
        do {
            let encoded = try JSONEncoder().encode(recentSearches)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to save recent searches: \(error)")
        }
    }
    
    // Load from UserDefaults with migration support
    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            // Try to decode with new format first
            recentSearches = try JSONDecoder().decode([RecentSearchItem].self, from: data)
        } catch {
            print("Failed to load recent searches (possibly old format): \(error)")
            // Clear the old data if it can't be decoded
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            recentSearches = []
        }
    }
}

// MARK: - Simplified Recent Search View (No Empty State)
struct RecentSearch: View {
    @ObservedObject var searchViewModel: SharedFlightSearchViewModel
    @State private var hasAppeared = false
    
    // Observe the shared recent search manager directly
    @ObservedObject private var recentSearchManager = RecentSearchManager.shared
    
    var body: some View {
        // UPDATED: Simplified - no empty state handling since HomeView handles conditional display
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(recentSearchManager.recentSearches.enumerated()), id: \.element.id) { index, search in
                    GeometryReader { geometry in
                        RecentSearchCard(
                            search: search,
                            onTap: {
                                // UPDATED: This now automatically triggers the search
                                recentSearchManager.applyRecentSearch(search, to: searchViewModel)
                            }
                        )
                        .scaleEffect(scaleValue(geometry))
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: hasAppeared
                        )
                    }
                    .frame(width: 180, height: 100)
                }
            }
            .padding()
            .padding(.bottom, 4)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
    }
    
    // Calculate scale based on position
    private func scaleValue(_ geometry: GeometryProxy) -> CGFloat {
        let midX = geometry.frame(in: .global).midX
        let viewWidth = UIScreen.main.bounds.width
        let distanceFromCenter = abs(midX - viewWidth / 2)
        let screenProportion = distanceFromCenter / (viewWidth / 2)
        
        // Scale between 1 (centered) and 0.9 (edges)
        return 1.0 - (0.1 * min(screenProportion, 1.0))
    }
}



// MARK: - UPDATED Recent Search Card with enhanced functionality (Original UI Design)
struct RecentSearchCard: View {
    let search: RecentSearchItem
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback for better user experience
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // ORIGINAL: Route display
                Text(search.displayRoute)
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // ORIGINAL: Class and passenger info layout
                HStack(spacing: 8) {
                    Text(search.cabinClass)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text(search.passengerInfo) // This uses the original passengerInfo property
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding()
            .padding(.vertical,5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPressed ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
            )
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // This will be handled by the main onTap
        }
    }
}
