import SwiftUI


struct MorphingSearchCard: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Binding var selectedTab: Int
    @Binding var isRoundTrip: Bool
    @Binding var isCollapsed: Bool
    let searchCardNamespace: Namespace.ID
    let handleBackNavigation: () -> Void
    let shouldShowBackButton: Bool
    let onDragCollapse: () -> Void
@GestureState private var dragOffset: CGFloat = 0
@State private var showLoadingWithDelay = false

    private var expandedHeight: CGFloat {
        let tripTabsHeight: CGFloat = 44  // Height of trip type tabs
        let topPadding: CGFloat = 15       // .padding(.top, 15)
        
        // Calculate search card height based on CURRENT SELECTED TAB, not just trip count
        let searchCardHeight: CGFloat = {
            // FIXED: Check selectedTab instead of just multiCityTrips.count
            if selectedTab == 2 && viewModel.multiCityTrips.count >= 2 {
                // Multi-city: only when tab is 2 AND we have multi-city trips
                let baseHeight: CGFloat = 170  // Increased from 150 to 170 (+20 more)
                let additionalTrips = max(0, viewModel.multiCityTrips.count - 2)
                let extraHeight = CGFloat(additionalTrips) * 75  // Increased from 70 to 75 (+5 more per trip)
                return baseHeight + extraHeight
            } else {
                // Regular trip (return/one-way): standard height for selectedTab 0 or 1
                return 60  // Your perfect value for return/one-way
            }
        }()
        
        // Padding based on CURRENT SELECTED TAB, not just trip count
        let searchCardVerticalPadding: CGFloat = (selectedTab == 2 && viewModel.multiCityTrips.count >= 2) ? 20 : 8
        let bottomPadding: CGFloat = (selectedTab == 2 && viewModel.multiCityTrips.count >= 2) ? 28 : 16
        let dividerSpacing: CGFloat = (selectedTab == 2 && viewModel.multiCityTrips.count >= 2) ? 12 : 4
        
        // Total calculated height
        let totalHeight = tripTabsHeight + topPadding + searchCardHeight +
                         searchCardVerticalPadding + bottomPadding + dividerSpacing
        
        return totalHeight
    }
    
private var collapsedHeight: CGFloat { 60 }

// Calculate current height based on collapsed state
private var currentHeight: CGFloat {
    isCollapsed ? collapsedHeight : expandedHeight
}

// Calculate progress between collapsed (0.0) and expanded (1.0)
private var heightProgress: CGFloat {
    isCollapsed ? 0.0 : 1.0
}

// Dynamic corner radius calculation
private var dynamicCornerRadius: CGFloat {
    let expandedRadius: CGFloat = 12
    let collapsedRadius: CGFloat = 12
    return collapsedRadius + (expandedRadius - collapsedRadius) * heightProgress
}

// Content opacity based on height
private var contentOpacity: Double {
    heightProgress > 0.1 ? min(1.0, (heightProgress - 0.1) / 0.2) : 0
}

// Collapsed content opacity
private var collapsedContentOpacity: Double {
    if heightProgress <= 0.3 {
        return 1.0 - (heightProgress / 0.3)
    } else {
        return 0.0
    }
}

private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
        .updating($dragOffset) { value, state, _ in
            state = value.translation.height
        }
        .onEnded { value in
            if value.translation.height < -20 {
                onDragCollapse()
            }
        }
}

var body: some View {
    VStack(spacing: 0) {
        ZStack(alignment: .top) {
            // Fixed chevron button overlay - always in same position
            HStack {
                if shouldShowBackButton {
                    Button(action: handleBackNavigation) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
            .zIndex(1)
            
            // Collapsed content - positioned at top, stays in place
            VStack {
                collapsedSearchContent
                    .opacity(collapsedContentOpacity)
              
            }
            
            // Expanded content with opacity animation
            if heightProgress > 0.05 {
                expandedSearchContent
                    .opacity(contentOpacity)
                    .scaleEffect(max(0.9, 0.9 + (heightProgress * 0.1)))
            }
        }
        .frame(height: currentHeight)
        .clipped()
    }
    .background(
        ZStack {
            // Single unified background that transitions smoothly
            RoundedRectangle(cornerRadius: dynamicCornerRadius)
                .fill(Color(.systemBackground))
            
            // Conditional border/loading overlay
            if shouldShowLoadingBorderForCurrentSearchType || showLoadingWithDelay {
                LoadingBorderView()
                    .cornerRadius(dynamicCornerRadius)
            } else {
                RoundedRectangle(cornerRadius: dynamicCornerRadius)
                    .stroke(Color.orange, lineWidth: 2)
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    )
    .padding()
    .gesture(dragGesture)
    .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: heightProgress)
    .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: isCollapsed)
    .onChange(of: shouldShowLoadingBorderForCurrentSearchType) { oldValue, newValue in
        if oldValue == true && newValue == false {
            showLoadingWithDelay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showLoadingWithDelay = false
            }
        }
    }
}

// MARK: - Expanded Content
@ViewBuilder
private var expandedSearchContent: some View {
    VStack(spacing: 0) {
        // Trip type tabs section (no back button here anymore)
        HStack {
            Spacer()
            TripTypeTabView(selectedTab: $selectedTab, isRoundTrip: $isRoundTrip, viewModel: viewModel)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 5)
        
        // Search card with dynamic values
        SearchCard(viewModel: viewModel, isRoundTrip: $isRoundTrip, selectedTab: selectedTab)
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
}

// MARK: - Collapsed Content
@ViewBuilder
private var collapsedSearchContent: some View {
    HStack {
        // Reserved space for back button (no button here, it's in overlay)
        HStack {
            Image(systemName: "chevron.left")
                .foregroundColor(.clear)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(width: 30)
        
        Spacer()
        
        // Compact trip info
        HStack(spacing: 8) {
            Text(getLocationDisplayText())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4, height: 4)
            
            Text(getDateDisplayText())
                .foregroundColor(.primary)
                .font(.system(size: 14, weight: .medium))
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4, height: 4)
            
            HStack {
                Image("cardpassenger")
                    .foregroundColor(.black)
                Text(getPassengerDisplayText())
                    .foregroundColor(.primary)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        
        Spacer()
        
        // Invisible spacer for balance
        HStack {
            Image(systemName: "chevron.left")
                .foregroundColor(.clear)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(width: 30)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .padding(.top, 5)
    .contentShape(Rectangle())
    .onTapGesture {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isCollapsed = false
        }
    }
}

// MARK: - Helper Methods
private var shouldShowLoadingBorderForCurrentSearchType: Bool {
    if viewModel.isDirectSearch {
        return viewModel.isLoadingDetailedFlights
    }
    
    return viewModel.isLoading ||
           viewModel.isLoadingFlights ||
           (viewModel.isLoadingDetailedFlights && !viewModel.hasInitialResultsLoaded) ||
           (viewModel.showingDetailedFlightList &&
            viewModel.detailedFlightResults.isEmpty &&
            viewModel.detailedFlightError == nil &&
            !viewModel.isDataCached)
}

private func getLocationDisplayText() -> String {
    let fromText: String = {
        if !viewModel.fromIataCode.isEmpty {
            return viewModel.fromIataCode
        } else if !viewModel.fromLocation.isEmpty {
            return viewModel.fromLocation
        } else {
            return "COK"
        }
    }()

    let toText: String = {
        if !viewModel.toIataCode.isEmpty && viewModel.toIataCode != "Anywhere" {
            return viewModel.toIataCode
        } else if !viewModel.toLocation.isEmpty {
            return viewModel.toLocation
        } else {
            return "Anywhere"
        }
    }()

    return "\(fromText) - \(toText)"
}

private func getDateDisplayText() -> String {
    if viewModel.dates.isEmpty && viewModel.selectedDepartureDatee.isEmpty {
        return "Anytime"
    }
    
    if viewModel.dates.isEmpty && viewModel.hasSearchedFlights && !viewModel.flightResults.isEmpty {
        return "Anytime"
    } else if viewModel.dates.isEmpty {
        return "Anytime"
    } else if viewModel.dates.count == 1 {
        return formatDate(viewModel.dates[0])
    } else if viewModel.dates.count >= 2 {
        return "\(formatDate(viewModel.dates[0])) - \(formatDate(viewModel.dates[1]))"
    }
    return "Anytime"
}

private func getPassengerDisplayText() -> String {
    let totalPassengers = viewModel.adultsCount + viewModel.childrenCount
    return "\(totalPassengers)"
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    return formatter.string(from: date)
}
}
