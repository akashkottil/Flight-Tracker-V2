import SwiftUI


struct SingleRowCard:View {
    
    @StateObject private var viewModel = ExploreViewModel()
    
    // Helper method to format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private func handleBackNavigation() {
        print("=== Back Navigation Debug ===")
        print("selectedFlightId: \(viewModel.selectedFlightId ?? "nil")")
        print("showingDetailedFlightList: \(viewModel.showingDetailedFlightList)")
        print("hasSearchedFlights: \(viewModel.hasSearchedFlights)")
        print("showingCities: \(viewModel.showingCities)")
        
        // First check if we have a selected flight in the detailed view
        if viewModel.selectedFlightId != nil {
            // If a flight is selected, deselect it first (go back to flight list)
            print("Action: Deselecting flight (going back to flight list)")
            viewModel.selectedFlightId = nil
        } else if viewModel.showingDetailedFlightList {
            // If no flight is selected but we're on detailed flight list, go back to previous level
            print("Action: Going back from flight list to previous level")
            viewModel.goBackToFlightResults()
        } else if viewModel.hasSearchedFlights {
            // Go back from flight results to cities
            print("Action: Going back from flight results to cities")
            viewModel.goBackToCities()
        } else if viewModel.showingCities {
            // Go back from cities to countries
            print("Action: Going back from cities to countries")
            viewModel.goBackToCountries()
        }
        print("=== End Back Navigation Debug ===")
    }

    
    
    var body: some View {
        VStack(spacing: 0) {
                HStack {
                    // Back button
                    Button(action: {
                        handleBackNavigation()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    Text(viewModel.fromLocation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Text("-")
                    Text(viewModel.toLocation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 6, height:6)
                    if viewModel.dates.isEmpty && viewModel.hasSearchedFlights && !viewModel.flightResults.isEmpty {
                        Text("Anytime")
                            .foregroundColor(.primary)
                            .font(.system(size: 14, weight: .medium))
                    } else if viewModel.dates.isEmpty {
                        Text("Anytime")
                            .foregroundColor(.primary)
                            .font(.system(size: 14, weight: .medium))
                    } else if viewModel.dates.count == 1 {
                        Text(formatDate(viewModel.dates[0]))
                            .foregroundColor(.primary)
                            .font(.system(size: 14, weight: .medium))
                    } else if viewModel.dates.count >= 2 {
                        Text("\(formatDate(viewModel.dates[0])) - \(formatDate(viewModel.dates[1]))")
                            .foregroundColor(.primary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .padding(.top, 5)
            
            }
            .background(
                ZStack {
                    // Background fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                    
                    // Animated or static stroke based on loading state
                    if viewModel.isLoading ||
                                          viewModel.isLoadingFlights ||
                                          (viewModel.isLoadingDetailedFlights && !viewModel.hasInitialResultsLoaded) ||
                                          (viewModel.showingDetailedFlightList && viewModel.detailedFlightResults.isEmpty && viewModel.detailedFlightError == nil && !viewModel.isDataCached) {
                                           LoadingBorderView()
                                       } else {
                                           RoundedRectangle(cornerRadius: 12)
                                               .stroke(Color.orange, lineWidth: 2)
                                       }
                }
            )
            .padding()
    }
}


#Preview {
    SingleRowCard()
}
