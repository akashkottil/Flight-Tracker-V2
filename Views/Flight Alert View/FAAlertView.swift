import SwiftUI

struct FAAlertView: View {
    
    // ADDED: Accept alerts data and callbacks
    let alerts: [AlertResponse]
    let onAlertDeleted: ((AlertResponse) -> Void)?
    let onNewAlertCreated: ((AlertResponse) -> Void)?
    
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    // ADDED: Default initializer for backward compatibility
    init(
        alerts: [AlertResponse] = [],
        onAlertDeleted: ((AlertResponse) -> Void)? = nil,
        onNewAlertCreated: ((AlertResponse) -> Void)? = nil
    ) {
        self.alerts = alerts
        self.onAlertDeleted = onAlertDeleted
        self.onNewAlertCreated = onNewAlertCreated
    }
    
    var body: some View {
        ZStack {
            GradientColor.BlueWhite
                .ignoresSafeArea()
            VStack {
                FAheader()
                
                // UPDATED: Always show alerts since we only reach this view when alerts exist
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Today's price drop alerts")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Real-time flight price monitoring")
                                    .font(.system(size: 14, weight: .regular))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // UPDATED: Display real alerts using FACard with delete callback
                        ForEach(alerts) { alert in
                            FACard(
                                alertData: alert,
                                onDelete: { deletedAlert in
                                    // Pass the delete action to parent
                                    onAlertDeleted?(deletedAlert)
                                }
                            )
                            .padding()
                        }
                        
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // Add new alert button
                    Button(action: {
                        showLocationSheet = true
                    }) {
                        HStack {
                            Image("FAPlus")
                            Text("Add new alert")
                        }
                        .padding()
                    }
                    
                    // Vertical divider
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 1, height: 50)
                    
                    // Hamburger button
                    Button(action: {
                        showMyAlertsSheet = true
                    }) {
                        HStack {
                            Image("FAHamburger")
                        }
                        .padding()
                    }
                }
                .foregroundColor(.white)
                .font(.system(size: 18))
                .background(Color("FABlue"))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            // UPDATED: Handle new alert creation and pass to parent
            FALocationSheet { newAlert in
                print("✅ New alert created in FAAlertView: \(newAlert.id)")
                
                // Pass the new alert to the parent via callback
                onNewAlertCreated?(newAlert)
            }
        }
        .sheet(isPresented: $showMyAlertsSheet) {
            // UPDATED: Pass real alert data to MyAlertsView
            MyAlertsView(
                alerts: alerts,
                onAlertDeleted: { deletedAlert in
                    // Handle alert deletion - pass to parent
                    onAlertDeleted?(deletedAlert)
                    
                    // Close the sheet if no alerts left
                    if alerts.count <= 1 {
                        showMyAlertsSheet = false
                    }
                },
                onNewAlertCreated: { newAlert in
                    // Handle new alert creation - pass to parent
                    onNewAlertCreated?(newAlert)
                    
                    // Close the sheet after creating new alert
                    showMyAlertsSheet = false
                }
            )
        }
    }
}

#Preview {
    FAAlertView(
        alerts: [
            AlertResponse(
                id: "sample-id-1",
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
            ),
            AlertResponse(
                id: "sample-id-2",
                user: AlertUserResponse(
                    id: "testId",
                    push_token: "token",
                    created_at: "2025-06-27T14:06:14.919574Z",
                    updated_at: "2025-06-27T14:06:14.919604Z"
                ),
                route: AlertRouteResponse(
                    id: 152,
                    origin: "JFK",
                    destination: "COK",
                    currency: "USD",
                    origin_name: "John F. Kennedy International Airport",
                    destination_name: "Cochin International Airport",
                    created_at: "2025-06-25T09:32:47.398234Z",
                    updated_at: "2025-06-27T14:06:14.932802Z"
                ),
                cheapest_flight: CheapestFlight(
                    id: 13600,
                    price: 799,
                    price_category: "average",
                    outbound_departure_timestamp: 1752624000,
                    outbound_departure_datetime: "2025-07-20T00:00:00Z",
                    outbound_is_direct: false,
                    inbound_departure_timestamp: nil,
                    inbound_departure_datetime: nil,
                    inbound_is_direct: nil,
                    created_at: "2025-06-25T09:32:47.620603Z",
                    updated_at: "2025-06-25T09:32:47.620615Z",
                    route: 152
                ),
                image_url: "https://image.explore.lascadian.com/city_95673507.webp",
                target_price: nil,
                last_notified_price: nil,
                created_at: "2025-06-27T14:06:14.947629Z",
                updated_at: "2025-06-27T14:06:14.947659Z"
            )
        ],
        onAlertDeleted: { alert in
            print("Alert deleted: \(alert.id)")
        },
        onNewAlertCreated: { alert in
            print("New alert created: \(alert.id)")
        }
    )
}
