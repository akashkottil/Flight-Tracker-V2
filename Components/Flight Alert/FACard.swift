// Views/Flight Alert View/FACard.swift
import SwiftUI

struct FACard: View {
    // ADDED: Optional alert data for displaying API response
    let alertData: AlertResponse?
    
    // ADDED: Default initializer for backward compatibility
    init(alertData: AlertResponse? = nil) {
        self.alertData = alertData
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ENHANCED: Show data from API response or default placeholder
            if let alert = alertData {
                // Display actual alert data from API
                realAlertContent(alert)
            } else {
                // Show placeholder content when no alert data
                placeholderContent()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Real Alert Content from API Response
    
    @ViewBuilder
    private func realAlertContent(_ alert: AlertResponse) -> some View {
        VStack(spacing: 16) {
            // Header with route information
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(alert.route.origin_name) → \(alert.route.destination_name)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(alert.route.origin) - \(alert.route.destination)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status badge
                VStack {
                    Text("Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green, lineWidth: 1)
                        )
                        .cornerRadius(6)
                }
            }
            
            // Price information
            if let cheapestFlight = alert.cheapest_flight {
                VStack(spacing: 12) {
                    HStack {
                        Text("Current Best Price")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(alert.route.currency) \(Int(cheapestFlight.price))")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                // Price category badge
                                Text(cheapestFlight.price_category.capitalized)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        cheapestFlight.price_category == "cheap" ? Color.green : Color.orange
                                    )
                                    .cornerRadius(4)
                                
                                // Direct flight indicator
                                if cheapestFlight.outbound_is_direct == true {
                                    Text("Direct")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Departure date if available
                        if let departureDate = cheapestFlight.outbound_departure_datetime {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Departure")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text(formatFlightDate(departureDate))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Alert details
            VStack(spacing: 8) {
                HStack {
                    Text("Alert Details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Created")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(formatAlertDate(alert.created_at))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Alert ID")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(String(alert.id.prefix(8)) + "...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement view details action
                    print("View details for alert: \(alert.id)")
                }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View Details")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: Implement delete alert action
                    print("Delete alert: \(alert.id)")
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Placeholder Content (Original Design)
    
    @ViewBuilder
    private func placeholderContent() -> some View {
        VStack(spacing: 16) {
            // Original header design
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mumbai → Delhi")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("BOM - DEL")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Text("Alert")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green, lineWidth: 1)
                        )
                        .cornerRadius(6)
                }
            }
            
            // Original price section
            VStack(spacing: 12) {
                HStack {
                    Text("Price dropped by 30%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("₹4,500")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("Cheap")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                            
                            Text("Direct")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Jul 16")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("06:00")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Original action buttons
            HStack(spacing: 12) {
                Button(action: {
                    print("View details tapped")
                }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View Details")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Button(action: {
                    print("Delete tapped")
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFlightDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formatAlertDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, yyyy"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Preview
struct FACard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with placeholder content
            FACard()
            
            // Preview with sample alert data
            FACard(alertData: sampleAlertResponse())
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // Sample alert data for preview
    private static func sampleAlertResponse() -> AlertResponse {
        return AlertResponse(
            id: "7c0df0ba-1a69-44a1-9a57-ac09c41bb4a4",
            user: AlertUserResponse(
                id: "testId",
                push_token: "demoToken26",
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
