import SwiftUI
import Combine
import CoreLocation

// MARK: - Enhanced HomeView with Gradual Search Card Collapse
struct HomeView: View {
    @State private var isAutoAnimating = false
    
    @State private var selectedDetailedFlightFilter: FlightFilterTabView.FilterOption = .best
    @State private var showingDetailedFlightFilterSheet = false
    @State private var hasAppliedInitialDirectFilter = false
    
    @Namespace private var animation
    @GestureState private var dragOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    @StateObject private var onboardingManager = OnboardingManager.shared
       @State private var showPushModal = false
       @State private var hasAppearedFromAppLaunch = false
    
    // NEW: Dynamic height calculation based on scroll offset
    @State private var searchCardHeight: CGFloat = 1.0 // Progress from 0.0 (collapsed) to 1.0 (expanded)
    
    // NEW: State for complete transformation to ExploreScreen
    @State private var isShowingExploreScreen = false
    @State private var homeContentOpacity: Double = 1.0
    @State private var exploreContentOpacity: Double = 0.0
    @State private var homeContentOffset: CGFloat = 0
    @State private var exploreContentOffset: CGFloat = 0
    
    // NEW: Enhanced animation states for skeletons and search card
    @State private var skeletonsVisible = false
    @State private var searchCardOvershoot = false
    
    // NEW: Collapsible card states for ExploreScreen
    @State private var isCollapsed = false
    @State private var exploreScrollOffset: CGFloat = 0
    
    // MARK: - State for tracking scroll velocity
    @State private var scrollEndTimer: Timer?
    
    // Shared view model for search functionality
    @StateObject private var searchViewModel = SharedFlightSearchViewModel()
    
    // Add CheapFlights view model
    @StateObject private var cheapFlightsViewModel = CheapFlightsViewModel()
    
    // UPDATED: Observe the recent search manager to track data changes
    @StateObject private var recentSearchManager = RecentSearchManager.shared
    
    // ADD: Track if we've shown the restored search to user
    @State private var hasShownRestoredSearch = false
    
    // NEW: ExploreViewModel for transformed results
    @StateObject private var exploreViewModel = ExploreViewModel()
    
    // NEW: State for explore screen components
    @State private var selectedTab = 0
    @State private var selectedFilterTab = 0
    @State private var selectedMonthTab = 0
    @State private var isRoundTrip: Bool = true
    @State private var showFilterModal = false
    
    private func applyDetailedFlightFilterOption(_ filter: FlightFilterTabView.FilterOption) {
        print("🔧 Applying detailed flight filter: \(filter.rawValue)")
        
        var filterRequest: FlightFilterRequest? = nil
        
        switch filter {
        case .best:
            filterRequest = FlightFilterRequest()
            
        case .best:
            filterRequest = FlightFilterRequest()
            
        case .cheapest:
            filterRequest = FlightFilterRequest()
            filterRequest!.sortBy = "price"
            filterRequest!.sortOrder = "asc"
            
        case .fastest:
            filterRequest = FlightFilterRequest()
            filterRequest!.sortBy = "duration"
            filterRequest!.sortOrder = "asc"
            
        case .direct:
            filterRequest = FlightFilterRequest()
            filterRequest!.stopCountMax = 0
        }
        
        // Apply the filter if we have one
        if let request = filterRequest {
            exploreViewModel.applyPollFilters(filterRequest: request)
        }
    }
    
    private func applyInitialDirectFilterIfNeeded() {
        if exploreViewModel.directFlightsOnlyFromHome && !hasAppliedInitialDirectFilter {
            print("🔧 Applying initial direct filter from HomeView toggle")
            selectedDetailedFlightFilter = .direct
            hasAppliedInitialDirectFilter = true
            applyDetailedFlightFilterOption(.direct)
        }
    }

    private func clearAllFiltersInHomeExploreScreen() {
        print("🧹 Clearing all filters in HomeView ExploreScreen")
        
        selectedDetailedFlightFilter = .best
        exploreViewModel.filterSheetState = ExploreViewModel.FilterSheetState()
        
        let emptyFilter = FlightFilterRequest()
        exploreViewModel.applyPollFilters(filterRequest: emptyFilter)
        
        print("✅ All filters cleared in HomeView ExploreScreen")
    }
    
    private func refreshHomeData() {
        // Refresh cheap flights data
        cheapFlightsViewModel.fetchCheapFlights()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment:.top) {
                
                GeometryReader { geometry in

                        VStack(spacing: 0) {
                            // Base gradient background (always present)
                            LinearGradient(
                                gradient: Gradient(colors: [Color("homeGrad"), Color.white]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: geometry.size.height * (isCollapsed ? 0.12 : 0.24))
                            .edgesIgnoringSafeArea(.top)

                        }

                    
                }
                // MARK: - Original Home Content
                VStack(spacing: 0) {
                    // Header + Search Inputs in a VStack with gradient background
                    VStack(spacing: 0) {
                        headerView
                            .zIndex(2) // Increased z-index for header

                        // NEW: Enhanced Dynamic Height Search Input with gradual collapse
                        EnhancedDynamicSearchInput(
                            searchViewModel: searchViewModel,
                            heightProgress: searchCardHeight,
                            onSearchTap: {
                                transformToExploreScreen()
                            }
                        )
                        .gesture(dragGesture)
                        .zIndex(1) // Ensure search input is above content
                        
                    }
                    .background(
                        LinearGradient(colors: [Color("homeGrad"), .white], startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea(edges: .top)
                    )
                    .zIndex(3) // Higher z-index for entire header section
                    
                    // IMPROVED: ScrollView with better offset tracking and proper spacing
                    ScrollView {
                        VStack(spacing: 16) {
                            // ADD: Reduced spacing at the top to bring content closer to search input
                            Spacer()
                                .frame(height: 4) // Reduced from 8 to 4 for even tighter spacing
                            
                            // Improved GeometryReader for scroll tracking
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKeyy.self,
                                        value: geo.frame(in: .named("scrollView")).minY
                                    )
                                    .onPreferenceChange(ScrollOffsetPreferenceKeyy.self) { value in
                                        scrollOffset = value
                                        updateSearchCardHeight()
                                        
                                        // Cancel existing timer and start new one
                                        scrollEndTimer?.invalidate()
                                        scrollEndTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                                            handleScrollEnd()
                                        }
                                    }
                            }
                            .frame(height: 0)

                            // UPDATED: Conditionally show recent search section
                            conditionalRecentSearchSection
                            
                            // Updated dynamic cheap flights section
                            dynamicCheapFlightsSection
                            
                            FeatureCards()
                            LoginNotifier()
                            ratingPrompt
                            BottomSignature()
                            
                            // Add extra padding at the bottom for better scrolling
                            Spacer().frame(height: 20)
                        }
                        .padding(.top, 4) // Reduced from 8 to 4 for even tighter spacing
                    }
                    .coordinateSpace(name: "scrollView")
                    .zIndex(0) // Lower z-index for scroll content
                }
                .opacity(homeContentOpacity)
                .offset(y: homeContentOffset)
                
                // MARK: - Complete ExploreScreen Overlay with Enhanced Animations
                if isShowingExploreScreen {
                    ZStack(alignment: .top) {
                        GeometryReader { geometry in
                                    VStack(spacing: 0) {
                                        Color("homeGrad")
                                            .frame(height: geometry.size.height * (isCollapsed ? 0.12 : 0.20)) // Reduced when collapsed
                                            .edgesIgnoringSafeArea(.top)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCollapsed)
                                        
                                        Spacer() // This will fill the remaining space with transparent/background
                                    }
                                }
                        VStack(spacing: 0) {
                            // Custom navigation bar - Collapsible with overshoot animation
                            MorphingSearchCard(
                                       viewModel: exploreViewModel,
                                       selectedTab: $selectedTab,
                                       isRoundTrip: $isRoundTrip,
                                       isCollapsed: $isCollapsed,
                                       searchCardNamespace: animation,
                                       handleBackNavigation: transformBackToHome,
                                       shouldShowBackButton: true,
                                       onDragCollapse: {
                                           withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                               isCollapsed = true
                                           }
                                       }
                                   )
                                   // Enhanced overshoot animation towards the top after search card is settled
                                   .offset(y: searchCardOvershoot ? -15 : 0)
                                   .animation(.spring(response: 0.7, dampingFraction: 0.65), value: searchCardOvershoot)
                            
                            // STICKY HEADER
                            stickyHeader
                            
                            // SCROLLABLE CONTENT with Enhanced Skeleton Animations
                            GeometryReader { geometry in
                                ScrollViewWithOffset(
                                    offset: $exploreScrollOffset,
                                    content: {
                                        VStack(alignment: .center, spacing: 16) {
                                            // Main content based on current state
                                            if exploreViewModel.showingDetailedFlightList {
                                                // Detailed flight list - highest priority
                                                ModifiedDetailedFlightListView(
                                                    viewModel: exploreViewModel,
                                                    isCollapsed: $isCollapsed,
                                                    showFilterModal: $showFilterModal
                                                )
                                                .transition(.move(edge: .trailing))
                                                .zIndex(1)
                                                .edgesIgnoringSafeArea(.all)
                                                .background(Color(.systemBackground))
                                            } else {
                                                // Enhanced skeleton cards with slide-in animation
                                                VStack(spacing: 16) {
                                                    ForEach(0..<5, id: \.self) { index in
                                                        EnhancedDetailedFlightCardSkeleton(
                                                            isRoundTrip: exploreViewModel.isRoundTrip,
                                                            isMultiCity: exploreViewModel.multiCityTrips.count >= 2 || (SharedSearchDataStore.shared.isDirectFromHome && SharedSearchDataStore.shared.selectedTab == 2),
                                                            multiCityLegsCount: exploreViewModel.multiCityTrips.count
                                                        )
                                                            .padding(.horizontal)
                                                            // Enhanced slide-in animation from bottom
                                                            .offset(y: skeletonsVisible ? 0 : 300)
                                                            .opacity(skeletonsVisible ? 1 : 0)
                                                            .scaleEffect(skeletonsVisible ? 1.0 : 0.8)
                                                            .animation(
                                                                .spring(
                                                                    response: 0.8,
                                                                    dampingFraction: 0.6,
                                                                    blendDuration: 0.1
                                                                )
                                                                .delay(Double(index) * 0.1),
                                                                value: skeletonsVisible
                                                            )
                                                    }
                                                }
                                                .padding(.top, 20)
                                            }
                                        }
                                        .background(Color("scroll"))
                                    }
                                )
                            }
                        }
                        .networkModal {
                            // Refresh functionality if needed
                        }
                        .filterModal(
                            isPresented: Binding(
                                get: { showFilterModal },
                                set: { showFilterModal = $0 }
                            ),
                            onClearFilters: {
                                clearAllFiltersInHomeExploreScreen()
                            }
                        )
                        .sheet(isPresented: $showingDetailedFlightFilterSheet) {
                            FlightFilterSheet(viewModel: exploreViewModel)
                        }
                    }
                    .background(Color("scroll"))
                    .opacity(exploreContentOpacity)
                    .offset(y: exploreContentOffset)
                    .onChange(of: exploreScrollOffset) { newOffset in
                        // Collapse when scrolled down more than 50 points and not already collapsed
                        let shouldCollapse = newOffset > 50
                        
                        if shouldCollapse && !isCollapsed {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isCollapsed = true
                            }
                        } else if !shouldCollapse && isCollapsed && newOffset < 20 {
                            // Expand when scrolled back up
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isCollapsed = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Fetch cheap flights data when home view appears
                cheapFlightsViewModel.fetchCheapFlights()
                
                // Show the restored search indicator briefly
                if searchViewModel.hasLastSearchData() && !hasShownRestoredSearch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasShownRestoredSearch = true
                        }
                    }
                }
            }
        }
        .networkModal {
            refreshHomeData()
        }
        .pushNotificationModal(
            shouldShow: showPushModal,
            onAllow: {
                print("User allowed notifications")
                showPushModal = false
                onboardingManager.pushNotificationModalDismissed()
            },
            onLater: {
                print("User chose later")
                showPushModal = false
                onboardingManager.pushNotificationModalDismissed()
            }
        )
        .onAppear {
            // Only show on app launch (when coming from ContentView), not on tab navigation
            if !hasAppearedFromAppLaunch {
                hasAppearedFromAppLaunch = true
                
                // UPDATED: Only show if onboarding manager specifically requests it
                // This will only be true immediately after completing/skipping onboarding
                if onboardingManager.shouldShowPushNotificationModal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showPushModal = true
                    }
                }
            }
        }
        .onChange(of: onboardingManager.shouldShowPushNotificationModal) { _, shouldShow in
            // Show if onboarding manager specifically requests it
            // (after authentication or "Maybe Later" is clicked)
            if shouldShow {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPushModal = true
                }
            }
        }
        
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Sticky Header
    private var stickyHeader: some View {
        VStack(spacing: 0) {
            // Only show header content when appropriate
            if exploreContentOpacity > 0.5 {
                // Animated Title Section with proper sliding
                HStack {
                    // Flight Results Title + Filter Tabs (slides in from right)
                    if exploreViewModel.showingDetailedFlightList {
                        VStack(spacing: 0) {
                            // Detailed Flight List Title
                            if !exploreViewModel.isDirectSearch {
                                HStack {
                                    Spacer()
                                    Text("Flights to \(exploreViewModel.toLocation)")
                                        .font(.system(size: 24, weight: .bold))
                                        .padding(.horizontal)
                                        .padding(.top, 16)
                                        .padding(.bottom, 8)
                                    Spacer()
                                }
                            }
                            
                            // FIXED: Filter tabs section for detailed flight list
                            HStack {
                                FilterButton(viewModel: exploreViewModel) {
                                    showingDetailedFlightFilterSheet = true
                                }
                                .padding(.leading, 20)
                                
                                FlightFilterTabView(
                                    selectedFilter: selectedDetailedFlightFilter,
                                    onSelectFilter: { filter in
                                        selectedDetailedFlightFilter = filter
                                        applyDetailedFlightFilterOption(filter)
                                    }
                                )
                            }
                            .padding(.trailing, 16)
                            .padding(.vertical, 8)
                            
                            // Flight count display
                            if exploreViewModel.isLoadingDetailedFlights || exploreViewModel.totalFlightCount > 0 {
                                HStack {
                                    FlightSearchStatusView(
                                        isLoading: exploreViewModel.isLoadingDetailedFlights,
                                        flightCount: exploreViewModel.totalFlightCount,
                                        destinationName: exploreViewModel.toLocation
                                    )
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                                .padding(.leading, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onAppear {
                            applyInitialDirectFilterIfNeeded()
                        }
                    }
                }
                .background(Color("scroll"))
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2), value: exploreViewModel.showingDetailedFlightList)
            }
        }
        .background(Color("scroll"))
        .zIndex(1)
    }

    
    // NEW: Function to update search card height based on scroll - IMPROVED NATIVE BEHAVIOR
    private func updateSearchCardHeight() {
        // Don't update if showing explore screen or if we're already auto-animating
        guard !isShowingExploreScreen && !isAutoAnimating else { return }
        
        let scrollThreshold: CGFloat = 120 // Increased threshold for more native feel
        let progress = max(0, min(1, (scrollOffset + scrollThreshold) / scrollThreshold))
        
        // More native behavior: smooth continuous animation without auto-snap
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.9, blendDuration: 0.1)) {
            searchCardHeight = progress
        }
    }

    // NEW: Function to handle scroll end - decides whether to collapse or expand
    private func handleScrollEnd() {
        guard !isShowingExploreScreen && !isAutoAnimating else { return }
        
        // Determine whether to collapse or expand based on current position
        if searchCardHeight < 0.5 {
            // Less than halfway - collapse
            triggerAutoCollapse()
        } else {
            // More than halfway - expand
            triggerAutoExpand()
        }
    }

    // UPDATED: More native auto-collapse behavior
    private func triggerAutoCollapse() {
        isAutoAnimating = true
        
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.1)) {
            searchCardHeight = 0.0
        }
        
        // Reset auto-animating flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAutoAnimating = false
        }
    }

    // UPDATED: More native auto-expand behavior
    private func triggerAutoExpand() {
        isAutoAnimating = true
        
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.1)) {
            searchCardHeight = 1.0
        }
        
        // Reset auto-animating flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAutoAnimating = false
        }
    }
    
    // NEW: Enhanced complete transformation to ExploreScreen with skeleton animations
    private func transformToExploreScreen() {
        print("🔄 Starting enhanced transformation to ExploreScreen")
        
        SharedSearchDataStore.shared.isDirectFromHome = true
        
        // Reset animation states
        skeletonsVisible = false
        searchCardOvershoot = false
        
        // Prevent interaction during transformation
        isShowingExploreScreen = true
        
        // Phase 1: Fade out home content and prepare explore content
        withAnimation(.easeInOut(duration: 0.3)) {
            homeContentOpacity = 0.0
            homeContentOffset = -50
        }
        
        // Phase 2: Transfer search data and initialize explore
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            transferSearchDataToExplore()
        }
        
        // Phase 3: Slide in explore content with search card (works exactly as before)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                exploreContentOpacity = 1.0
                exploreContentOffset = 0
            }
        }
        
        // Phase 4: After search card is settled, add overshoot towards top (earlier and more movement)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                searchCardOvershoot = true
            }
        }
        
        // Phase 5: Skeleton cards slide in from bottom with staggered overshoot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                skeletonsVisible = true
            }
        }
    }
    
    // NEW: Transform back to HomeView
    private func transformBackToHome() {
        print("🏠 Transforming back to HomeView")
        
        // 🔥 SYNC CHANGES BACK TO HOME BEFORE TRANSFORMATION
        syncExploreChangesToHome()
        
        SharedSearchDataStore.shared.isDirectFromHome = false
        
        // Phase 1: Hide skeletons first
        withAnimation(.easeOut(duration: 0.25)) {
            skeletonsVisible = false
        }
        
        // Phase 2: Hide explore content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.3)) {
                exploreContentOpacity = 0.0
                exploreContentOffset = 50
            }
        }
        
        // Phase 3: Show home content and reset search card height
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                homeContentOpacity = 1.0
                homeContentOffset = 0
                isShowingExploreScreen = false
                searchCardHeight = 1.0
            }
        }
        
        // Reset explore view model and animation states
        exploreViewModel.resetToInitialState()
        isCollapsed = false
        exploreScrollOffset = 0
        searchCardOvershoot = false
        skeletonsVisible = false
    }
    
    // REPLACE the existing transferSearchDataToExplore method in HomeView with this:

    private func transferSearchDataToExplore() {
        print("🔥 Transferring search data to explore - selectedTab: \(searchViewModel.selectedTab)")
        print("🔥 Multi-city trips count: \(searchViewModel.multiCityTrips.count)")
        
        // Transfer all search data to the explore view model
        exploreViewModel.fromLocation = searchViewModel.fromLocation
        exploreViewModel.toLocation = searchViewModel.toLocation
        exploreViewModel.fromIataCode = searchViewModel.fromIataCode
        exploreViewModel.toIataCode = searchViewModel.toIataCode
        exploreViewModel.dates = searchViewModel.selectedDates
        exploreViewModel.isRoundTrip = searchViewModel.isRoundTrip
        exploreViewModel.adultsCount = searchViewModel.adultsCount
        exploreViewModel.childrenCount = searchViewModel.childrenCount
        exploreViewModel.childrenAges = searchViewModel.childrenAges
        exploreViewModel.selectedCabinClass = searchViewModel.selectedCabinClass
        
        // 🔥 FIX: Clear multi-city trips when not in multi-city mode
        if searchViewModel.selectedTab == 2 {
            exploreViewModel.multiCityTrips = searchViewModel.multiCityTrips
            print("🔥 Transferred \(exploreViewModel.multiCityTrips.count) multi-city trips to explore view model")
        } else {
            exploreViewModel.multiCityTrips = [] // Clear multi-city trips for regular searches
            print("🔥 Cleared multi-city trips for regular search")
        }
        
        // Set the selected origin and destination codes
        exploreViewModel.selectedOriginCode = searchViewModel.fromIataCode
        exploreViewModel.selectedDestinationCode = searchViewModel.toIataCode
        
        // Mark as direct search to show detailed flight list
        exploreViewModel.isDirectSearch = true
        exploreViewModel.showingDetailedFlightList = true
        
        // Store direct flights preference
        exploreViewModel.directFlightsOnlyFromHome = searchViewModel.directFlightsOnly
        
        // ADDED: Reset filter states for new search
        exploreViewModel.resetFilterSheetStateForNewSearch()
        selectedDetailedFlightFilter = .best
        hasAppliedInitialDirectFilter = false
        
        // Sync tab states - CRITICAL for multi-city
        selectedTab = searchViewModel.selectedTab
        isRoundTrip = searchViewModel.isRoundTrip
        
        print("🔥 Final selectedTab in explore: \(selectedTab)")
        print("🔥 Is multi-city search: \(searchViewModel.selectedTab == 2)")
        
        // UPDATED: Handle multi-city vs regular search
        if searchViewModel.selectedTab == 2 && !searchViewModel.multiCityTrips.isEmpty {
            // Multi-city search
            print("🔥 Executing multi-city search from home with \(searchViewModel.multiCityTrips.count) trips")
            
            // Ensure exploreViewModel has the multi-city trips
            if exploreViewModel.multiCityTrips.isEmpty {
                exploreViewModel.multiCityTrips = searchViewModel.multiCityTrips
                print("🔥 Re-assigned multi-city trips to explore view model")
            }
            
            // Start multi-city search
            exploreViewModel.searchMultiCityFlights()
        } else {
            // Regular search - format dates for API
            print("🔥 Executing regular search (selectedTab: \(selectedTab))")
            
            if !searchViewModel.selectedDates.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if searchViewModel.selectedDates.count >= 2 {
                    let sortedDates = searchViewModel.selectedDates.sorted()
                    exploreViewModel.selectedDepartureDatee = formatter.string(from: sortedDates[0])
                    exploreViewModel.selectedReturnDatee = formatter.string(from: sortedDates[1])
                } else if searchViewModel.selectedDates.count == 1 {
                    exploreViewModel.selectedDepartureDatee = formatter.string(from: searchViewModel.selectedDates[0])
                    if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: searchViewModel.selectedDates[0]) {
                        exploreViewModel.selectedReturnDatee = formatter.string(from: nextDay)
                    }
                }
            }
            
            // Initiate the regular search
            exploreViewModel.searchFlightsForDates(
                origin: searchViewModel.fromIataCode,
                destination: searchViewModel.toIataCode,
                returnDate: searchViewModel.isRoundTrip ? exploreViewModel.selectedReturnDatee : "",
                departureDate: exploreViewModel.selectedDepartureDatee,
                isDirectSearch: true
            )
        }
        
        print("🔥 Transfer and search initiation completed")
    }

    // MARK: - Drag Gesture for manual search card manipulation
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                if value.translation.height < -20 {
                    // Drag up - collapse
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        searchCardHeight = 0.3
                    }
                } else if value.translation.height > 20 {
                    // Drag down - expand
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        searchCardHeight = 1.0
                    }
                }
            }
    }

    // MARK: - Header View - UPDATED FOR NATIVE NAVIGATION
    var headerView: some View {
        HStack {
            Image("logoHome")
                .resizable()
                .frame(width: 28, height: 28)
                .cornerRadius(6)
                .padding(.trailing, 4)

            Text("All Flights")
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            // UPDATED: Use NavigationLink for native navigation
            NavigationLink(destination: AccountView()) {
                Image("homeProfile")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - UPDATED: Conditional Recent Search Section
    @ViewBuilder
    private var conditionalRecentSearchSection: some View {
        if !recentSearchManager.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent Search")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            recentSearchManager.clearAllRecentSearches()
                        }
                    }) {
                        Text("Clear All")
                            .foregroundColor(Color("ThridColor"))
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)

                RecentSearch(searchViewModel: searchViewModel)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.95)),
                removal: .move(edge: .top)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.95))
            ))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: recentSearchManager.recentSearches.isEmpty)
        }
    }

    // MARK: - Dynamic Cheap Flights Section
    var dynamicCheapFlightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("Cheapest Fares From ")
                    .fontWeight(.medium)
                + Text(cheapFlightsViewModel.fromLocationName)
                    .foregroundColor(.blue)

                Image(systemName: "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            DynamicCheapFlights(viewModel: cheapFlightsViewModel)
        }
    }
    
    // MARK: - Rating Prompt
    var ratingPrompt: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("gradientBlueLeft"), Color("gradientBlueRight")]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .cornerRadius(12)
            
            HStack {
                Image("starImg")
                    .resizable()
                    .frame(width: 40, height: 40)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("How do you feel?")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Rate us On Appstore")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Rate Us")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color("buttonBlue"))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    // ADD THIS NEW METHOD:
    private func syncExploreChangesToHome() {
        print("🔄 Syncing changes from ExploreScreen back to HomeView")
        
        searchViewModel.fromLocation = exploreViewModel.fromLocation
        searchViewModel.toLocation = exploreViewModel.toLocation
        searchViewModel.fromIataCode = exploreViewModel.fromIataCode
        searchViewModel.toIataCode = exploreViewModel.toIataCode
        searchViewModel.selectedDates = exploreViewModel.dates
        searchViewModel.isRoundTrip = exploreViewModel.isRoundTrip
        searchViewModel.adultsCount = exploreViewModel.adultsCount
        searchViewModel.childrenCount = exploreViewModel.childrenCount
        searchViewModel.childrenAges = exploreViewModel.childrenAges
        searchViewModel.selectedCabinClass = exploreViewModel.selectedCabinClass
        searchViewModel.directFlightsOnly = exploreViewModel.directFlightsOnlyFromHome
        
        // 🔥 MOST IMPORTANT: Sync multi-city trips back to home
        searchViewModel.multiCityTrips = exploreViewModel.multiCityTrips
        
        searchViewModel.selectedTab = selectedTab
        
        if exploreViewModel.multiCityTrips.count >= 2 {
            searchViewModel.selectedTab = 2
            selectedTab = 2
        }
        
        print("✅ Synced \(exploreViewModel.multiCityTrips.count) multi-city trips back to home")
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
