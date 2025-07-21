import SwiftUI

struct APIResponse: Codable {
    let results: [FlightPrice]
}

struct FlightPrice: Codable {
    let date: TimeInterval  // Unix timestamp
    let price: Int
    let price_category: String
}

struct LanguageData: Codable {
    var months: MonthNames
    var days: DayNames
    
    struct MonthNames: Codable {
        var full: [String]
        var short: [String]
    }
    
    struct DayNames: Codable {
        var full: [String]
        var short: [String]
        var min: [String]
    }
}

struct DateSelection {
    var selectedDates: [Date] = []
    var selectionState: SelectionState = .none
    
    enum SelectionState {
        case none
        case firstDateSelected
        case rangeSelected
    }
}

struct CalendarFormatting {
    private static let dateCache = NSCache<NSString, NSString>()
    private static let timeCache = NSCache<NSString, NSString>()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static func monthString(for date: Date, languageData: LanguageData?, calendar: Calendar) -> String {
        if let languageData = languageData {
            let monthIndex = calendar.component(.month, from: date) - 1
            if monthIndex >= 0 && monthIndex < languageData.months.short.count {
                return languageData.months.short[monthIndex]
            }
        }
        return monthFormatter.string(from: date)
    }
    
    static func yearString(for date: Date) -> String {
        return yearFormatter.string(from: date)
    }
    
    static func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "MMM DD, YYYY" }
        
        let cacheKey = "\(date.timeIntervalSince1970)" as NSString
        if let cachedResult = dateCache.object(forKey: cacheKey) {
            return cachedResult as String
        }
        
        let result = fullDateFormatter.string(from: date)
        dateCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }
    
    static func formattedTime(_ date: Date) -> String {
        let cacheKey = "\(date.timeIntervalSince1970)" as NSString
        if let cachedResult = timeCache.object(forKey: cacheKey) {
            return cachedResult as String
        }
        
        let result = timeFormatter.string(from: date)
        timeCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @Binding var fromiatacode: String
    @Binding var toiatacode: String
    @Binding var parentSelectedDates: [Date]
    
    // Add this new callback for handling Anytime selection
        var onAnytimeSelection: (([FlightResult]) -> Void)? = nil
    
    // Add callback for trip type changes
       var onTripTypeChange: ((Bool) -> Void)? = nil
    
    // Add isRoundTrip parameter to know the current trip type
        var isRoundTrip: Bool = true
   
   
    @State private var priceData: [Date: (Int, String)] = [:]
    private let calendar = Calendar.current
    
    // MARK: - Language Properties
    @State private var languages: [String: LanguageData] = [:]
    @State private var selectedLanguage: String = "English"
    @State private var showLanguagePicker = false
    
    // MARK: - State
    @State private var dateSelection = DateSelection()
    @State private var currentMonth = Date()
    @State private var showingMonths = 12
    
    // Time selection
    @State private var timeSelection: Bool = false // Changed to false to match the screenshot
    @State private var departureTime = Date()
    @State private var showDepartureTimePicker: Bool = false
    @State private var returnTime = Date()
    @State private var showReturnTimePicker: Bool = false
    
    // Single or range selection
    @State private var singleDate: Bool = true
    
    // Controls whether to show the return date selector
    @State private var showReturnDateSelector: Bool = false
    
    private func isRangeStartDate(_ date: Date) -> Bool {
        guard dateSelection.selectedDates.count >= 2 else { return false }
        let sortedDates = dateSelection.selectedDates.sorted()
        return calendar.isDate(date, inSameDayAs: sortedDates.first!)
    }

    private func isRangeEndDate(_ date: Date) -> Bool {
        guard dateSelection.selectedDates.count >= 2 else { return false }
        let sortedDates = dateSelection.selectedDates.sorted()
        return calendar.isDate(date, inSameDayAs: sortedDates.last!)
    }
    
    struct LeftCurvedBorder: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let radius = rect.height / 2
            let cornerRadius: CGFloat = 6 // Small curve for corners only
            
            // Start from top-left corner with curve
            path.move(to: CGPoint(x: radius, y: 0))
            
            // Top edge to right corner with slight curve
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cornerRadius),
                             control: CGPoint(x: rect.maxX, y: 0))
            
            // Right edge (mostly straight with curved corners)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                             control: CGPoint(x: rect.maxX, y: rect.maxY))
            
            // Bottom edge to curve start
            path.addLine(to: CGPoint(x: radius, y: rect.maxY))
            
            // Left curved edge (main curve)
            path.addArc(center: CGPoint(x: radius, y: radius),
                       radius: radius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(270),
                       clockwise: false)
            
            path.closeSubpath()
            return path
        }
    }

    struct RightCurvedBorder: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let radius = rect.height / 2
            let cornerRadius: CGFloat = 6 // Small curve for corners only
            
            // Start from top-left corner with slight curve
            path.move(to: CGPoint(x: 0, y: cornerRadius))
            
            // Left edge (mostly straight with curved corners)
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - cornerRadius))
            path.addQuadCurve(to: CGPoint(x: cornerRadius, y: rect.maxY),
                             control: CGPoint(x: 0, y: rect.maxY))
            
            // Bottom edge to curve start
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
            
            // Right curved edge (main curve)
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: radius),
                       radius: radius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(270),
                       clockwise: true)
            
            // Top edge from curve to left corner with slight curve
            path.addLine(to: CGPoint(x: cornerRadius, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: cornerRadius),
                             control: CGPoint(x: 0, y: 0))
            
            path.closeSubpath()
            return path
        }
    }
    
    
    
    var isMultiCity: Bool = false
       var multiCityTripIndex: Int = 0
       var multiCityViewModel: ExploreViewModel? = nil
    
    var sharedMultiCityViewModel: SharedFlightSearchViewModel? = nil
    
    init(
            fromiatacode: Binding<String>,
            toiatacode: Binding<String>,
            parentSelectedDates: Binding<[Date]>,
            onAnytimeSelection: (([FlightResult]) -> Void)? = nil,
            onTripTypeChange: ((Bool) -> Void)? = nil,
            isRoundTrip: Bool = true,
            isMultiCity: Bool = false,
            multiCityTripIndex: Int = 0,
            multiCityViewModel: ExploreViewModel? = nil,
            sharedMultiCityViewModel: SharedFlightSearchViewModel? = nil
        ) {
            self._fromiatacode = fromiatacode
            self._toiatacode = toiatacode
            self._parentSelectedDates = parentSelectedDates
            self.onAnytimeSelection = onAnytimeSelection
            self.onTripTypeChange = onTripTypeChange
            self.isRoundTrip = isRoundTrip
            self.isMultiCity = isMultiCity
            self.multiCityTripIndex = multiCityTripIndex
            self.multiCityViewModel = multiCityViewModel
            self.sharedMultiCityViewModel = sharedMultiCityViewModel
        }
    
    // MARK: - Computed Properties
    var selectedDates: [Date] {
        dateSelection.selectedDates
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // New header view that matches the screenshot
            calendarHeaderView
            
            // Weekday header
            weekdayHeaderView
                .background(Color.white)
            
            // Main calendar content
            ScrollView {
                VStack(spacing: 0) {
                    // Display multiple months
                    ForEach(0..<showingMonths, id: \.self) { monthOffset in
                        if let date = calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) {
                            monthSectionView(for: date)
                        }
                    }
                }
                .padding(.bottom, 80) // Add padding at bottom to account for fixed Continue button
            }
            
            // Bottom Continue button (always visible)
            // Bottom Continue button (always visible)
            ContinueButtonView(
                tripType: isMultiCity ? "Multi-City" : (showReturnDateSelector ? "Round Trip" : "One Way"),
                price: getLowestPrice(),
                onContinue: {
                    if isMultiCity {
                        // Handle both types of view models
                        if let viewModel = multiCityViewModel,
                           !dateSelection.selectedDates.isEmpty,
                           multiCityTripIndex < viewModel.multiCityTrips.count {
                            viewModel.multiCityTrips[multiCityTripIndex].date = dateSelection.selectedDates[0]
                        } else if let sharedViewModel = sharedMultiCityViewModel,
                                  !dateSelection.selectedDates.isEmpty,
                                  multiCityTripIndex < sharedViewModel.multiCityTrips.count {
                            sharedViewModel.multiCityTrips[multiCityTripIndex].date = dateSelection.selectedDates[0]
                        }
                    } else {
                        // In regular mode, update the parentSelectedDates
                        parentSelectedDates = dateSelection.selectedDates
                    }
                    dismiss()
                }
            )
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        }
        .onAppear {
            loadLanguageData()
            
            // Special handling for multi-city mode
            if isMultiCity {
                // Force single date selection mode
                singleDate = true
                showReturnDateSelector = false
                
                // Handle both types of view models
                if let viewModel = multiCityViewModel,
                   multiCityTripIndex < viewModel.multiCityTrips.count {
                    let tripDate = viewModel.multiCityTrips[multiCityTripIndex].date
                    dateSelection.selectedDates = [tripDate]
                    dateSelection.selectionState = .firstDateSelected
                    currentMonth = tripDate
                } else if let sharedViewModel = sharedMultiCityViewModel,
                          multiCityTripIndex < sharedViewModel.multiCityTrips.count {
                    let tripDate = sharedViewModel.multiCityTrips[multiCityTripIndex].date
                    dateSelection.selectedDates = [tripDate]
                    dateSelection.selectionState = .firstDateSelected
                    currentMonth = tripDate
                }
            } else {
                singleDate = !isRoundTrip
                showReturnDateSelector = isRoundTrip
                // Initialize dateSelection with parentSelectedDates
                if !parentSelectedDates.isEmpty {
                    dateSelection.selectedDates = parentSelectedDates
                    
                    // Update selection state based on number of dates
                    if parentSelectedDates.count == 1 {
                        dateSelection.selectionState = .firstDateSelected
                    } else if parentSelectedDates.count > 1 {
                        dateSelection.selectionState = .rangeSelected
                        showReturnDateSelector = true
                    }
                }
            }
            
            // Fetch prices for the current month
            fetchMonthlyPrices(for: currentMonth)
        }
    }
    
    // MARK: - Calendar Header View
    private var calendarHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.headline)
                        .padding()
                }
                
                Text(isMultiCity ? "Select Date" : "Dates")
                                .font(.headline)
                
                Spacer()
                
                if !isMultiCity {
                               Button("Anytime") {
                                   // Handle anytime selection
                                       fetchAnytimePrices { results in
                                           // Dismiss the calendar view
                                           dismiss()
                                           // Pass the results to the parent view
                                           onAnytimeSelection?(results)
                                       }
                               }
                               .foregroundColor(.blue)
                               .fontWeight(.semibold)
                               .padding()
                           }
                       }
            .padding(.vertical)
                       .padding(.horizontal)
            
            // In multi-city mode, show a simpler header
            if isMultiCity {
                HStack(spacing: 15) {
                    VStack(alignment: .leading) {
                        if dateSelection.selectedDates.isEmpty {
                            Text("Flight Date")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        } else {
                            Text(formatted(date: dateSelection.selectedDates[0]))  // ← FIXED: Use formatted function
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .padding(.horizontal)
                }
            }
            else{
                HStack(spacing: 15) {
                    if dateSelection.selectedDates.isEmpty {
                        // No dates selected yet - show placeholders
                        // Departure date selector
                        VStack(alignment: .leading) {
                            Text("Departure")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .padding(.leading)
                        
                        // Return date selector or Add Return button
                        if showReturnDateSelector {
                            VStack(alignment: .leading) {
                                Text("Return")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.trailing)
                        } else {
                            Button(action: {
                                showReturnDateSelector = true
                                singleDate = false
                                // Notify parent about trip type change
                                onTripTypeChange?(true) // true for round trip
                            }) {
                                Text("Add Return")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.trailing)
                        }
                    } else {
                        // Show selected dates with X button
                        if let departureDate = dateSelection.selectedDates.first {
                            // Departure date display
                            HStack {
                                
                                
                                Text(formatted(date: departureDate))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Clear this date
                                    if dateSelection.selectedDates.count > 1 {
                                        dateSelection.selectedDates.removeFirst()
                                        dateSelection.selectionState = .firstDateSelected
                                    } else {
                                        dateSelection.selectedDates = []
                                        dateSelection.selectionState = .none
                                    }
                                }) {
                                    ZStack{
                                        Circle()
                                            .foregroundColor(.gray.opacity(0.2))
                                            .frame(width:24,height:24)
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(Color.white)
                            )
                            .padding(.leading)
                        }
                        
                        // Return date if available
                        if dateSelection.selectedDates.count > 1, let returnDate = dateSelection.selectedDates.last {
                            HStack {
                                Text(formatted(date: returnDate))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Clear this date
                                    dateSelection.selectedDates.removeLast()
                                    dateSelection.selectionState = .firstDateSelected
                                }) {
                                    ZStack{
                                        Circle()
                                            .foregroundColor(.gray.opacity(0.2))
                                            .frame(width:24,height:24)
                                            
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(Color.white)
                            )
                            .padding(.trailing)
                        } else if showReturnDateSelector {
                            // Empty return date selector
                            VStack(alignment: .leading) {
                                Text("Return")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.trailing)
                        } else {
                            // Add Return button
                            Button(action: {
                                showReturnDateSelector = true
                                singleDate = false
                                
                                // Notify parent about trip type change
                                onTripTypeChange?(true) // true for round trip
                            }) {
                                Text("Add Return")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.trailing)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .background(Color.white)
    }
    
    private func fetchAnytimePrices(completion: @escaping ([FlightResult]) -> Void) {
        guard !fromiatacode.isEmpty && !toiatacode.isEmpty else {
            completion([])
            return
        }
        
        // Fix: Don't use guard let for non-optional values
        let origin = fromiatacode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fromiatacode
        let destination = toiatacode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toiatacode
        
        // Rest of the method remains the same
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let formattedDate = dateFormatter.string(from: currentDate)
        
        let urlString = "https://staging.plane.lascade.com/api/price/?currency=\(CurrencyManager.shared.currencyCode)&country=\(CurrencyManager.shared.countryCode)"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(CurrencyManager.shared.countryCode, forHTTPHeaderField: "country")
        
        let payload: [String: Any] = [
            "origin": origin,
            "destination": destination,
            "departure": formattedDate,
            "round_trip": isRoundTrip
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            completion([])
            return
        }
        request.httpBody = httpBody
        
        print("🔍 Fetching anytime prices for \(origin) → \(destination)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ API Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(FlightSearchResponse.self, from: data)
                print("✅ Decoded \(decoded.results.count) flight entries")
                
                DispatchQueue.main.async {
                    completion(decoded.results)
                }
            } catch {
                print("❌ Failed to decode API response:", error)
                // Print the raw data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(responseString)")
                }
                completion([])
            }
        }.resume()
    }
    
    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: date)
    }
    
    // MARK: - Weekday Header View
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
            }
        }
        .padding(.vertical, 10)
       
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
        .padding(.bottom,10)
    }
    
    // MARK: - Enhanced month section view with better price fetching
    private func monthSectionView(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Month header
            HStack {
                Text("\(CalendarFormatting.monthString(for: date, languageData: languages[selectedLanguage], calendar: calendar)) , \(CalendarFormatting.yearString(for: date))")
                    .font(.headline)
                    .padding(.leading)
                    .padding(.top, 10)
                
                Spacer()
                
                Button("Select Month") {
                    selectEntireMonth(date)
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.trailing)
                .padding(.top, 10)
            }
            .padding(.top,20)
            .padding(.bottom,20)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                let days = getDaysInMonth(for: date)
                
                ForEach(days.indices, id: \.self) { index in
                    if let dayDate = days[index] {
                        DayViewWithPrice(
                            date: dayDate,
                            isSelected: isDateSelected(dayDate),
                            calendar: calendar,
                            priceData: priceData,
                            isInRange: isDateInRange(dayDate),
                            isRangeSelection: dateSelection.selectedDates.count > 1,
                            dateSelection: dateSelection  // ADD this line
                        )
                        .onTapGesture {
                            handleDateSelection(dayDate)
                        }
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.bottom, 20)
            .onAppear {
                // Fetch prices when this month becomes visible
                // Only fetch if we don't already have price data for this month
                let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let normalizedFirst = calendar.startOfDay(for: firstOfMonth)
                
                // Check if we already have price data for this month
                let hasDataForMonth = priceData.keys.contains { priceDate in
                    calendar.isDate(priceDate, equalTo: normalizedFirst, toGranularity: .month)
                }
                
                if !hasDataForMonth {
                    print("🔄 Fetching prices for month: \(date)")
                    fetchMonthlyPrices(for: date)
                }
            }
        }
    }
    
    // MARK: - Enhanced DayViewWithPrice with better debugging
    struct DayViewWithPrice: View {
        let date: Date
        let isSelected: Bool
        let calendar: Calendar
        let priceData: [Date: (Int, String)]
        let isInRange: Bool
        let isRangeSelection: Bool
        let dateSelection: DateSelection
        
        @ViewBuilder
        private func overlayView(for date: Date) -> some View {
            if isPastDate {
                Color.clear
            } else if isSelected {
                if isRangeSelection && dateSelection.selectedDates.count >= 2 {
                    // Range selection - use curved borders
                    if isRangeStartDate(date) {
                        LeftCurvedBorder()
                            .stroke(Color(hex: "#0044AB"), lineWidth: 1)
                    } else if isRangeEndDate(date) {
                        RightCurvedBorder()
                            .stroke(Color(hex: "#0044AB"), lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(hex: "#0044AB"), lineWidth: 1)
                    }
                } else {
                    // Single date selection
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(hex: "#0044AB"), lineWidth: 1)
                }
            } else {
                Color.clear
            }
        }

        // Also add these helper methods inside DayViewWithPrice
        private func isRangeStartDate(_ date: Date) -> Bool {
            guard dateSelection.selectedDates.count >= 2 else { return false }
            let sortedDates = dateSelection.selectedDates.sorted()
            return calendar.isDate(date, inSameDayAs: sortedDates.first!)
        }

        private func isRangeEndDate(_ date: Date) -> Bool {
            guard dateSelection.selectedDates.count >= 2 else { return false }
            let sortedDates = dateSelection.selectedDates.sorted()
            return calendar.isDate(date, inSameDayAs: sortedDates.last!)
        }
        
        private var day: Int {
            calendar.component(.day, from: date)
        }
        
        private var price: Int? {
            let normalizedDate = calendar.startOfDay(for: date)
            return priceData[normalizedDate]?.0
        }
        
        private var priceCategory: String? {
            let normalizedDate = calendar.startOfDay(for: date)
            return priceData[normalizedDate]?.1
        }
        
        private var isPastDate: Bool {
            let today = calendar.startOfDay(for: Date())
            return calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
        }
        
        var body: some View {
            VStack(spacing: 5) {
                // Day number
                Text("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(
                        isPastDate ? Color.black.opacity(0.4) :
                            (isSelected ? Color(hex: "#0044AB") : .black)
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? Color.clear : Color.clear)
                    )
                    .overlay(
                        overlayView(for: date)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isInRange && !isSelected && !isPastDate && isRangeSelection ?
                                  Color.blue.opacity(0.2) : Color.clear)
                    )
                
                // Price display
                if let price = price, !isPastDate {
                    Text(CurrencyManager.shared.formatPrice(price))
                        .font(.system(size: 12))
                        .foregroundColor(getPriceColor(for: priceCategory ?? "normal"))
                } else {
                    // Empty text to maintain consistent spacing
                    Text("")
                        .font(.system(size: 12))
                }
            }
            .frame(height: 50)
            .opacity(isPastDate ? 0.5 : 1.0)
            .contentShape(Rectangle()) // Ensure the entire cell is tappable
        }
        
        private func getPriceColor(for category: String) -> Color {
            switch category.lowercased() {
            case "cheap":
                return .green
            case "expensive":
                return .red
            case "normal":
                return .gray
            default:
                return .primary
            }
        }
    }
    
    private func selectEntireMonth(_ date: Date) {
        let calendar = Calendar.current
        
        // Get the first day of the month
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return
        }
        
        // If this is a one-way trip (single date)
        if !showReturnDateSelector {
            // Select the first non-past day of the month
            let today = calendar.startOfDay(for: Date())
            var dayToSelect = firstDayOfMonth
            
            // Find the first non-past day
            while calendar.compare(dayToSelect, to: today, toGranularity: .day) == .orderedAscending {
                dayToSelect = calendar.date(byAdding: .day, value: 1, to: dayToSelect) ?? dayToSelect
                
                // If we've gone to the next month, there are no valid days to select
                if calendar.component(.month, from: dayToSelect) != calendar.component(.month, from: date) {
                    return
                }
            }
            
            // Select the first available day
            dateSelection.selectedDates = [dayToSelect]
            dateSelection.selectionState = .firstDateSelected
        } else {
            // This is a round-trip (range selection)
            let today = calendar.startOfDay(for: Date())
            
            // Find the first non-past day
            var startDate = firstDayOfMonth
            while calendar.compare(startDate, to: today, toGranularity: .day) == .orderedAscending {
                startDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                
                // If we've gone to the next month, there are no valid days to select
                if calendar.component(.month, from: startDate) != calendar.component(.month, from: date) {
                    return
                }
            }
            
            // Get the last day of the month
            let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)
            guard let numberOfDaysInMonth = range?.count,
                  let lastDayOfMonth = calendar.date(byAdding: .day, value: numberOfDaysInMonth - 1, to: firstDayOfMonth) else {
                return
            }
            
            // Select the range from the first available day to the last day of the month
            dateSelection.selectedDates = [startDate, lastDayOfMonth]
            dateSelection.selectionState = .rangeSelected
        }
        
        
    }
    
    // Get the lowest price for the selected trip
    private func getLowestPrice() -> Int {
        if dateSelection.selectedDates.isEmpty {
            // If no dates selected, find the lowest price in the priceData
            if let minPrice = priceData.values.map({ $0.0 }).min() {
                return minPrice
            }
            return 198 // Default price if no data available
        } else if dateSelection.selectedDates.count == 1, let selectedDate = dateSelection.selectedDates.first {
            // If only one date is selected, get its price if available
            let normalizedDate = calendar.startOfDay(for: selectedDate)
            if let price = priceData[normalizedDate]?.0 {
                return price
            }
            return 198 // Default price if price for the selected date is not available
        } else if dateSelection.selectedDates.count >= 2 {
            // If two dates are selected (round trip), calculate total price
            // Here you might want to sum prices or implement your own pricing logic
            var totalPrice = 0
            for date in dateSelection.selectedDates {
                let normalizedDate = calendar.startOfDay(for: date)
                if let price = priceData[normalizedDate]?.0 {
                    totalPrice += price
                
                }
            }
            return totalPrice > 0 ? totalPrice : 198
        }
        
        return 198 // Default price
    }
    
    // MARK: - Continue Button View
    struct ContinueButtonView: View {
        let tripType: String
        let price: Int
        let onContinue: () -> Void
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tripType)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("from \(CurrencyManager.shared.formatPrice(price))")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 130, height: 52)
                        .background(Color("buttonColor"))
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
    }
    
    // MARK: - Helper Methods
    private func isDateSelected(_ date: Date) -> Bool {
        dateSelection.selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func isPastDate(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        // If we have two dates selected, check if this date is between them
        if dateSelection.selectedDates.count >= 2,
           let firstDate = dateSelection.selectedDates.first,
           let lastDate = dateSelection.selectedDates.last {
            
            let normalizedDate = calendar.startOfDay(for: date)
            let normalizedFirst = calendar.startOfDay(for: firstDate)
            let normalizedLast = calendar.startOfDay(for: lastDate)
            
            return normalizedDate >= normalizedFirst && normalizedDate <= normalizedLast
        }
        return false
    }
    
    // MARK: - Enhanced handleDateSelection with better validation
    private func handleDateSelection(_ date: Date) {
        // Ensure we can't select past dates
        if isPastDate(date) {
            print("🚫 Attempted to select past date: \(date)")
            return
        }
        
        print("📅 Date selected: \(date)")
        
        // In multi-city mode, always enforce single date selection
        if isMultiCity {
            dateSelection.selectedDates = [date]
            dateSelection.selectionState = .firstDateSelected
            print("✈️ Multi-city: Selected single date")
            return
        }
        
        // Check if we're in one-way mode (either singleDate is true OR viewModel indicates one-way)
        let isOneWayMode = singleDate || !isRoundTrip 
        
        // Regular mode date selection logic
        if isOneWayMode && !showReturnDateSelector {
            // Single date mode
            dateSelection.selectedDates = [date]
            dateSelection.selectionState = .firstDateSelected
            print("📅 Single date mode: Selected \(date)")
        } else {
            // Round-trip mode: allow range selection
            switch dateSelection.selectionState {
            case .none:
                dateSelection.selectedDates = [date]
                dateSelection.selectionState = .firstDateSelected
                print("📅 First date selected: \(date)")
                
            case .firstDateSelected:
                if calendar.isDate(date, inSameDayAs: dateSelection.selectedDates[0]) {
                    print("📅 Same date selected, ignoring")
                    return
                }
                
                let startDate = min(date, dateSelection.selectedDates[0])
                let endDate = max(date, dateSelection.selectedDates[0])
                dateSelection.selectedDates = [startDate, endDate]
                dateSelection.selectionState = .rangeSelected
                print("📅 Range selected: \(startDate) to \(endDate)")
                
            case .rangeSelected:
                // Start over with new date
                dateSelection.selectedDates = [date]
                dateSelection.selectionState = .firstDateSelected
                print("📅 Range reset, new first date: \(date)")
            }
        }
    }
    
   
    // MARK: - Fixed getDaysInMonth method
    private func getDaysInMonth(for date: Date) -> [Date?] {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        // Get the actual number of days in this specific month
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let daysInMonth = range.count
        
        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        // Create array with empty slots for days before the 1st of the month
        var days = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        // Add all days in the month
        for day in 1...daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(dayDate)
            }
        }
        
        // Fill remaining cells to complete the week grid (ensures consistent layout)
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            for _ in 0..<remainingCells {
                days.append(nil)
            }
        }
        
        return days
    }
    
    // MARK: - Fixed fetchMonthlyPrices method for bulk API response
    private func fetchMonthlyPrices(for selectedDate: Date) {
        guard !fromiatacode.isEmpty && !toiatacode.isEmpty else { return }
        
        guard let origin = fromiatacode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let destination = toiatacode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let formattedDate = dateFormatter.string(from: firstOfMonth)

        let urlString = "https://staging.plane.lascade.com/api/price/?currency=\(CurrencyManager.shared.currencyCode)&country=\(CurrencyManager.shared.countryCode)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(CurrencyManager.shared.countryCode, forHTTPHeaderField: "country")

        let payload: [String: Any] = [
            "origin": origin,
            "destination": destination,
            "departure": formattedDate,
            "round_trip": true
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody

        print("🔍 Fetching prices for: \(formattedDate) (\(origin) → \(destination))")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ API Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 API Response: \(responseString.prefix(200))...")
            }
            
            do {
                let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
                print("✅ Decoded \(decoded.results.count) price entries")
                
                DispatchQueue.main.async {
                    var newPriceData: [Date: (Int, String)] = [:]
                    
                    for item in decoded.results {
                        // Convert Unix timestamp to Date
                        let date = Date(timeIntervalSince1970: item.date)
                        // Normalize to start of day in local timezone
                        let normalizedDate = calendar.startOfDay(for: date)
                        newPriceData[normalizedDate] = (item.price, item.price_category)
                        
                        // Debug: Print some sample dates
                        if newPriceData.count <= 5 {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            print("💰 Price for \(formatter.string(from: normalizedDate)): $\(item.price) (\(item.price_category))")
                        }
                    }
                    
                    print("📊 Total price data entries: \(newPriceData.count)")
                    
                    // Merge with existing price data (don't overwrite, just add new data)
                    for (date, priceInfo) in newPriceData {
                        self.priceData[date] = priceInfo
                    }
                    
                    print("📈 Total price data after merge: \(self.priceData.count)")
                }
            } catch {
                print("❌ Failed to decode API response:", error)
                // Print the raw data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(responseString)")
                }
            }
        }.resume()
    }
    
    private func loadLanguageData() {
        guard let fileURL = Bundle.main.url(forResource: "calendar_localizations", withExtension: "json"),
              let jsonData = try? Data(contentsOf: fileURL) else {
            print("Failed to load language data file")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            languages = try decoder.decode([String: LanguageData].self, from: jsonData)
            
            if languages.keys.contains("English") {
                selectedLanguage = "English"
            } else {
                selectedLanguage = languages.keys.sorted().first ?? selectedLanguage
            }
        } catch {
            print("Error decoding language data: \(error)")
        }
    }
}



struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var dates: [Date] = []
            @State private var fromIataCode: String = "COK"
            @State private var toIataCode: String = "DXB"

            var body: some View {
                CalendarView(fromiatacode: $fromIataCode, toiatacode: $toIataCode, parentSelectedDates: $dates)
            }
        }
        
        return PreviewWrapper()
    }
}
