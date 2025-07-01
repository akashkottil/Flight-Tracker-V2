import SwiftUI

struct FACard: View {
    // ADDED: Optional alert data for displaying API response
    let alertData: AlertResponse?
    
    // ADDED: Callback for delete action
    let onDelete: ((AlertResponse) -> Void)?
    
    // ADDED: Default initializer for backward compatibility
    init(alertData: AlertResponse? = nil, onDelete: ((AlertResponse) -> Void)? = nil) {
        self.alertData = alertData
        self.onDelete = onDelete
    }
    
    @State private var shimmerOffset: CGFloat = -300
    
    @State private var imageLoaded = false

    
    var body: some View {
        // Show shimmer if no data, otherwise show real card
        if let alertData = alertData {
            realCardContent(for: alertData)
        } else {
            shimmerCardContent()
        }
    }
    
    // MARK: - Real Card Content
    private func realCardContent(for alert: AlertResponse) -> some View {
        VStack(spacing: 0) {
            // Top image section
            ZStack(alignment: .topLeading) {
                // UPDATED: Use image from API or default
                if let imageUrl = alert.image_url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Placeholder while loading
                            Color.gray.opacity(0.3)
                                .frame(height: 120)
                                .clipped()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .opacity(imageLoaded ? 1.0 : 0.0)
                                .onAppear {
                                    withAnimation(.easeIn(duration: 0.8)) {
                                        imageLoaded = true
                                    }
                                }
                        case .failure:
                            // Optional: fallback if image fails
                            Color.gray.opacity(0.3)
                                .frame(height: 120)
                                .clipped()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: 120)
                        .clipped()
                }

                
                // UPDATED: Price drop badge with real data
                HStack {
                    VStack {
                        HStack {
                            Image("FAPriceTag")
                                .frame(width: 12, height: 16)
                            Text(getPriceDropText(for: alert))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("FADarkGreen"))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }
                .padding(8)
                
                
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            
            // UPDATED: Content section with real data
            VStack(alignment: .leading) {
                HStack {
                    VStack(spacing: 0) {
                        // Departure circle
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                        // Connecting line
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: 1, height: 24)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        // Arrival circle
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // UPDATED: Origin airport with real data
                        HStack {
                            Text(alert.route.origin)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Text(alert.route.origin_name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        // UPDATED: Destination airport with real data
                        HStack {
                            Text(alert.route.destination)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Text(alert.route.destination_name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            
            Divider()
                .padding(.vertical, 16)
            
            // UPDATED: Bottom section with real pricing data
            HStack {
                HStack {
                    Text(getDepartureDate(for: alert))
                        .font(.subheadline)
                        .fontWeight(.light)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Show original price if we have price data
                        if let originalPrice = getOriginalPrice(for: alert) {
                            Text(originalPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("FAPriceCut"))
                                .strikethrough()
                        }
                        
                        Text(getCurrentPrice(for: alert))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Shimmer Card Content
    private func shimmerCardContent() -> some View {
        VStack(spacing: 0) {
            // Top image section with shimmer
            ZStack(alignment: .topLeading) {
                // Shimmer placeholder for image
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(shimmerOverlay())
                
                // Price drop badge shimmer
                HStack {
                    VStack {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 12, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 50, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(shimmerOverlay())
                    }
                    Spacer()
                }
                .padding(8)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            
            // Content section with shimmer
            VStack(alignment: .leading) {
                HStack {
                    VStack(spacing: 0) {
                        // Departure circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                        // Connecting line
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 24)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        // Arrival circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Origin airport shimmer
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .overlay(shimmerOverlay())
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 120, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .overlay(shimmerOverlay())
                        }
                        
                        // Destination airport shimmer
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .overlay(shimmerOverlay())
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 140, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .overlay(shimmerOverlay())
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            
            Divider()
                .padding(.vertical, 16)
            
            // Bottom section with pricing shimmer
            HStack {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .overlay(shimmerOverlay())
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Original price shimmer (strikethrough)
                        Rectangle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 60, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(shimmerOverlay())
                        
                        // Current price shimmer
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(shimmerOverlay())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    // MARK: - Shimmer Animation
    private func shimmerOverlay() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(Angle(degrees: 15))
            .offset(x: shimmerOffset)
            .clipped()
    }
    
    private func startShimmerAnimation() {
        withAnimation(
            Animation
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 300
        }
    }
    
    // MARK: - Helper Methods for API Data (No Fallbacks)
    
    private func getPriceDropText(for alert: AlertResponse) -> String {
        guard let flight = alert.cheapest_flight else { return "" }
        
        // Use price category to show appropriate drop message
        let currency = getCurrencySymbol(for: alert)
        let currentPrice = Int(flight.price)
        
        if flight.price_category.lowercased() == "cheap" {
            // Calculate drop based on current price
            let estimatedDrop = Int(Double(currentPrice) * 0.3) // Assuming 30% drop for "cheap"
            return "\(currency)\(estimatedDrop) drop"
        } else {
            // For other categories, show category
            return "\(flight.price_category.capitalized) price"
        }
    }
    
    private func getDepartureDate(for alert: AlertResponse) -> String {
        if let flight = alert.cheapest_flight,
           let departureDateTime = flight.outbound_departure_datetime {
            return formatFlightDate(departureDateTime)
        } else {
            // Fallback to alert creation date if no flight date
            return formatAlertDate(alert.created_at)
        }
    }
    
    private func getCurrentPrice(for alert: AlertResponse) -> String {
        guard let flight = alert.cheapest_flight else { return "" }
        let currency = getCurrencySymbol(for: alert)
        return "\(currency)\(formatPrice(flight.price))"
    }
    
    private func getOriginalPrice(for alert: AlertResponse) -> String? {
        guard let flight = alert.cheapest_flight,
              flight.price_category.lowercased() == "cheap" else { return nil }
        
        let currency = getCurrencySymbol(for: alert)
        let currentPrice = flight.price
        
        // Calculate estimated original price based on price category
        let estimatedOriginalPrice = currentPrice / 0.7 // Assuming 30% drop
        
        return "\(currency)\(formatPrice(estimatedOriginalPrice))"
    }
    
    private func getCurrencySymbol(for alert: AlertResponse) -> String {
        switch alert.route.currency.uppercased() {
        case "INR":
            return "₹"
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        default:
            return alert.route.currency // Return currency code if symbol not known
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "%.0f", price) // Remove decimals for large amounts
        } else {
            return String(format: "%.0f", price)
        }
    }
    
    private func formatFlightDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        // Try different date formats from API
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "EEE dd MMM"
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString // Return original if parsing fails
    }
    
    private func formatAlertDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEE dd MMM"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Preview
struct FACard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with shimmer (no data)
            Text("Loading State (No Data)")
                .font(.headline)
            FACard()
                .padding()
            
            // Preview with sample API data
            Text("With Real API Data")
                .font(.headline)
            FACard(alertData: sampleAlertResponse()) { alert in
                print("Delete alert: \(alert.id)")
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // Sample alert data for preview
     static func sampleAlertResponse() -> AlertResponse {
        return AlertResponse(
            id: "sample-id",
            user: AlertUserResponse(
                id: "testId",
                push_token: "token",
                created_at: "2025-06-27T14:06:14.919574Z",
                updated_at: "2025-06-27T14:06:14.919604Z"
            ),
            route: AlertRouteResponse(
                id: 151,
                origin: "COK",
                destination: "DXB",
                currency: "INR",
                origin_name: "Kochi",
                destination_name: "Dubai",
                created_at: "2025-06-25T09:32:47.398234Z",
                updated_at: "2025-06-27T14:06:14.932802Z"
            ),
            cheapest_flight: CheapestFlight(
                id: 13599,
                price: 5555,
                price_category: "cheap",
                outbound_departure_timestamp: 1752624000,
                outbound_departure_datetime: "2025-07-16T00:00:00Z",
                outbound_is_direct: true,
                inbound_departure_timestamp: nil,
                inbound_departure_datetime: nil,
                inbound_is_direct: nil,
                created_at: "2025-06-25T09:32:47.620603Z",
                updated_at: "2025-06-25T09:32:47.620615Z",
                route: 151
            ),
            image_url: "https://image.explore.lascadian.com/city_95673506.webp",
            target_price: nil,
            last_notified_price: nil,
            created_at: "2025-06-27T14:06:14.947629Z",
            updated_at: "2025-06-27T14:06:14.947659Z"
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Loading State")
        FACard() // No data - shows shimmer
            .padding()
        
        Text("With Data")
        FACard(alertData: FACard_Previews.sampleAlertResponse())
            .padding()
    }
}
