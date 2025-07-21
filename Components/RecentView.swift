import SwiftUI

// MARK: - Recent Location Search View
struct RecentLocationSearchView: View {
    @ObservedObject private var recentSearchManager = RecentLocationSearchManager.shared
    let onLocationSelected: (AutocompleteResult) -> Void
    let showAnywhereOption: Bool
    let onAnywhereSelected: (() -> Void)?
    
    // ADD: Search type filter
    let searchType: LocationSearchType?
    
    init(onLocationSelected: @escaping (AutocompleteResult) -> Void,
         showAnywhereOption: Bool = false,
         onAnywhereSelected: (() -> Void)? = nil,
         searchType: LocationSearchType? = nil) {
        self.onLocationSelected = onLocationSelected
        self.showAnywhereOption = showAnywhereOption
        self.onAnywhereSelected = onAnywhereSelected
        self.searchType = searchType
    }
    
    // ADD: Computed property for filtered searches
    private var filteredRecentSearches: [RecentLocationSearch] {
        if let searchType = searchType {
            return recentSearchManager.getRecentSearches(for: searchType)
        } else {
            return recentSearchManager.recentSearches
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !filteredRecentSearches.isEmpty || showAnywhereOption {
                // Header with title and clear button
                HStack {
                    Text("Recent Searches")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !filteredRecentSearches.isEmpty {
                        Button("Clear") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if let searchType = searchType {
                                    recentSearchManager.clearRecentSearches(for: searchType)
                                } else {
                                    recentSearchManager.clearAllRecentSearches()
                                }
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
               
               
                
                // Content in ScrollView
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Anywhere option (for destination search) - same style as search results
                        if showAnywhereOption {
                            AnywhereOptionRow()
                                .onTapGesture {
                                    onAnywhereSelected?()
                                }
                            
                            if !filteredRecentSearches.isEmpty {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Recent searches list using the same LocationResultRow as search results
                        ForEach(filteredRecentSearches) { recentSearch in
                            // Convert RecentLocationSearch to AutocompleteResult to use same component
                            let autocompleteResult = AutocompleteResult(
                                iataCode: recentSearch.iataCode,
                                airportName: recentSearch.airportName,
                                type: recentSearch.type,
                                displayName: recentSearch.displayName,
                                cityName: recentSearch.cityName,
                                countryName: recentSearch.countryName,
                                countryCode: "", // Not needed for recent searches
                                imageUrl: recentSearch.imageUrl,
                                coordinates: AutocompleteCoordinates(latitude: "0", longitude: "0") // Not needed
                            )
                            
                            // Use the exact same LocationResultRow component as search results
                            LocationResultRow(result: autocompleteResult)
                                .onTapGesture {
                                    onLocationSelected(autocompleteResult)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            recentSearchManager.removeRecentSearch(recentSearch)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}
