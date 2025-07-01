
import SwiftUI

struct TrackCalendar: View {
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    
    @State private var selectedDate: Date?
    @State private var currentMonth = Date()
    @State private var showingMonths = 6 // Reduced for tracking purposes
    
    private let calendar = Calendar.current
    
    // MARK: - Language Properties (simplified)
    @State private var languages: [String: LanguageData] = [:]
    @State private var selectedLanguage: String = "English"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
                .padding(.bottom, 80) // Add padding for continue button
            }
            
            // Bottom Continue button
            ContinueButtonView(
                selectedDate: selectedDate,
                onContinue: {
                    if let date = selectedDate {
                        onDateSelected(date)
                        isPresented = false
                    }
                }
            )
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        }
        .onAppear {
            loadLanguageData()
        }
    }
    
    // MARK: - Calendar Header View
    private var calendarHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding()
                }
                
                Text("Select Date")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Selected date display
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    if let selectedDate = selectedDate {
                        Text(formatted(date: selectedDate))
                            .font(.subheadline)
                            .foregroundColor(.primary)
//                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        Text("Departure date")
                            .font(.subheadline)
                            .foregroundColor(.primary)
//                            .padding(.horizontal)
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
            .padding(.bottom)
        }
        .background(Color.white)
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
        .padding(.bottom, 10)
    }
    
    // MARK: - Month section view
    private func monthSectionView(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Month header
            HStack {
                Text("\(CalendarFormatting.monthString(for: date, languageData: languages[selectedLanguage], calendar: calendar)), \(CalendarFormatting.yearString(for: date))")
                    .font(.headline)
                    .padding(.leading)
                    .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {
                let days = getDaysInMonth(for: date)
                
                ForEach(days.indices, id: \.self) { index in
                    if let dayDate = days[index] {
                        DayView(
                            date: dayDate,
                            isSelected: isDateSelected(dayDate),
                            calendar: calendar
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
        }
    }
    
    // MARK: - Day View
    struct DayView: View {
        let date: Date
        let isSelected: Bool
        let calendar: Calendar
        
        private var day: Int {
            calendar.component(.day, from: date)
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
                        isPastDate ? Color.gray.opacity(0.5) :
                            (isSelected ? Color(hex: "#0044AB") : .black)
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? Color.clear : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isSelected ? Color(hex: "#0044AB") : Color.clear, lineWidth: 1)
                    )
                
                // Empty space for consistency
                Text("")
                    .font(.system(size: 12))
            }
            .frame(height: 50)
            .opacity(isPastDate ? 0.5 : 1.0)
            .contentShape(Rectangle()) // Ensure the entire cell is tappable
        }
    }
    
    // MARK: - Continue Button View
    struct ContinueButtonView: View {
        let selectedDate: Date?
        let onContinue: () -> Void
        
        var body: some View {
            HStack {
//                VStack(alignment: .leading, spacing: 2) {
//                    Text("Selected Date")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                    if let selectedDate = selectedDate {
//                        Text(formatDisplayDate(selectedDate))
//                            .font(.headline)
//                            .foregroundColor(.black)
//                    } else {
//                        Text("No date selected")
//                            .font(.headline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                
//                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
//                        .frame(width: 120, height: 44)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background( Color(hex: "#F87B0E"))
                        .cornerRadius(8)
                }
                .disabled(selectedDate == nil)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        
        
        private func formatDisplayDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Helper Methods
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(selectedDate, inSameDayAs: date)
    }
    
    private func isPastDate(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
    }
    
    private func handleDateSelection(_ date: Date) {
        // Ensure we can't select past dates
        if isPastDate(date) {
            print("🚫 Attempted to select past date: \(date)")
            return
        }
        
        selectedDate = date
        print("📅 Date selected: \(date)")
    }
    
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

// MARK: - Supporting Types (reusing from existing calendar)
// These are already defined in your existing codebase, but included here for completeness

struct TrackCalendarFormatting {
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
}

// MARK: - Preview
struct TrackCalendar_Previews: PreviewProvider {
    static var previews: some View {
        TrackCalendar(
            isPresented: .constant(true),
            onDateSelected: { date in
                print("Selected date: \(date)")
            }
        )
    }
}
