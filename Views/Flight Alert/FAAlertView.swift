import SwiftUI

struct FAAlertView: View {
    
    // UPDATED: Explicit control over all states
    let alerts: [AlertResponse]
    let isLoadingShimmer: Bool
    let showAddButton: Bool
    let onAlertDeleted: ((AlertResponse) -> Void)?
    let onNewAlertCreated: ((AlertResponse) -> Void)?
    let onAlertUpdated: ((AlertResponse) -> Void)?  // NEW: Added edit callback
    
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    init(
        alerts: [AlertResponse] = [],
        isLoadingShimmer: Bool = false,
        showAddButton: Bool = true,
        onAlertDeleted: ((AlertResponse) -> Void)? = nil,
        onNewAlertCreated: ((AlertResponse) -> Void)? = nil,
        onAlertUpdated: ((AlertResponse) -> Void)? = nil  // NEW: Added edit callback
    ) {
        self.alerts = alerts
        self.isLoadingShimmer = isLoadingShimmer
        self.showAddButton = showAddButton
        self.onAlertDeleted = onAlertDeleted
        self.onNewAlertCreated = onNewAlertCreated
        self.onAlertUpdated = onAlertUpdated  // NEW: Initialize edit callback
    }
    
    var body: some View {
        ZStack {
            GradientColor.BlueWhite
                .ignoresSafeArea()
            VStack {
                FAheader()
                
                // Main content area
                ScrollView(showsIndicators: false) {
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
                        
                        // FIXED: Clear shimmer vs real card logic
                        if isLoadingShimmer {
                            // Show shimmer cards ONLY during manual refresh
                            ForEach(0..<max(alerts.count, 3), id: \.self) { index in
                                FAShimmerCard()
                                    .padding()
                                    .id("shimmer-\(index)")
                            }
                        } else {
                            // Show real alert cards
                            ForEach(alerts) { alert in
                                FACard(
                                    alertData: alert,
                                    onDelete: { deletedAlert in
                                        onAlertDeleted?(deletedAlert)
                                    }
                                )
                                .padding()
                                .id("alert-\(alert.id)")
                            }
                        }
                        
                        Color.clear
                            .frame(height: 100)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: isLoadingShimmer)
            }
            
            // FIXED: Button only shows when explicitly told to
            if showAddButton {
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
                        .disabled(isLoadingShimmer)
                        .opacity(isLoadingShimmer ? 0.7 : 1.0)
                        
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
                        .disabled(isLoadingShimmer)
                        .opacity(isLoadingShimmer ? 0.7 : 1.0)
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .background(Color("FABlue"))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .bottom)),
                    removal: .scale(scale: 0.8)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .bottom))
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showAddButton)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            FALocationSheet { newAlert in
                print("✅ New alert created: \(newAlert.id)")
                onNewAlertCreated?(newAlert)
            }
        }
        .sheet(isPresented: $showMyAlertsSheet) {
            MyAlertsView(
                alerts: alerts,
                onAlertDeleted: { deletedAlert in
                    onAlertDeleted?(deletedAlert)
                    
                    // Close sheet if no alerts left
                    if alerts.count <= 1 {
                        showMyAlertsSheet = false
                    }
                },
                onNewAlertCreated: { newAlert in
                    onNewAlertCreated?(newAlert)
                    showMyAlertsSheet = false
                },
                onAlertUpdated: { updatedAlert in  // NEW: Handle alert updates
                    print("🔄 Alert updated in FAAlertView: \(updatedAlert.id)")
                    onAlertUpdated?(updatedAlert)
                    // Note: Don't close the sheet here, let user continue managing alerts
                }
            )
        }
    }
}

// MARK: - Previews for Testing

//#Preview("Normal State - Button Visible") {
//    FAAlertView(
//        alerts: [
//            AlertResponse(
//                id: "sample-id-1",
//                user: AlertUserResponse(
//                    id: "testId",
//                    push_token: "token",
//                    created_at: "2025-06-27T14:06:14.919574Z",
//                    updated_at: "2025-06-27T14:06:14.919604Z"
//                ),
//                route: AlertRouteResponse(
//                    id: 151,
//                    origin: "COK",
//                    destination: "DXB",
//                    currency: "INR",
//                    origin_name: "Kochi",
//                    destination_name: "Dubai",
//                    created_at: "2025-06-25T09:32:47.398234Z",
//                    updated_at: "2025-06-27T14:06:14.932802Z"
//                ),
//                cheapest_flight: CheapestFlight(
//                    id: 13599,
//                    price: 5555,
//                    price_category: "cheap",
//                    outbound_departure_timestamp: 1752624000,
//                    outbound_departure_datetime: "2025-07-16T00:00:00Z",
//                    outbound_is_direct: true,
//                    inbound_departure_timestamp: nil,
//                    inbound_departure_datetime: nil,
//                    inbound_is_direct: nil,
//                    created_at: "2025-06-25T09:32:47.620603Z",
//                    updated_at: "2025-06-25T09:32:47.620615Z",
//                    route: 151
//                ),
//                image_url: "https://image.explore.lascadian.com/city_95673506.webp",
//                target_price: nil,
//                last_notified_price: nil,
//                created_at: "2025-06-27T14:06:14.947629Z",
//                updated_at: "2025-06-27T14:06:14.947659Z"
//            )
//        ],
//        isLoadingShimmer: false,
//        showAddButton: true,
//        onAlertDeleted: { alert in
//            print("Alert deleted: \(alert.id)")
//        },
//        onNewAlertCreated: { alert in
//            print("New alert created: \(alert.id)")
//        },
//        onAlertUpdated: { alert in  // NEW: Added for preview
//            print("Alert updated: \(alert.id)")
//        }
//    )
//}

//#Preview("Shimmer Refresh - Button Visible") {
//    FAAlertView(
//        alerts: [
//            AlertResponse(
//                id: "sample-id-1",
//                user: AlertUserResponse(
//                    id: "testId",
//                    push_token: "token",
//                    created_at: "2025-06-27T14:06:14.919574Z",
//                    updated_at: "2025-06-27T14:06:14.919604Z"
//                ),
//                route: AlertRouteResponse(
//                    id: 151,
//                    origin: "COK",
//                    destination: "DXB",
//                    currency: "INR",
//                    origin_name: "Kochi",
//                    destination_name: "Dubai",
//                    created_at: "2025-06-25T09:32:47.398234Z",
//                    updated_at: "2025-06-27T14:06:14.932802Z"
//                ),
//                cheapest_flight: CheapestFlight(
//                    id: 13599,
//                    price: 5555,
//                    price_category: "cheap",
//                    outbound_departure_timestamp: 1752624000,
//                    outbound_departure_datetime: "2025-07-16T00:00:00Z",
//                    outbound_is_direct: true,
//                    inbound_departure_timestamp: nil,
//                    inbound_departure_datetime: nil,
//                    inbound_is_direct: nil,
//                    created_at: "2025-06-25T09:32:47.620603Z",
//                    updated_at: "2025-06-25T09:32:47.620615Z",
//                    route: 151
//                ),
//                image_url: "https://image.explore.lascadian.com/city_95673506.webp",
//                target_price: nil,
//                last_notified_price: nil,
//                created_at: "2025-06-27T14:06:14.947629Z",
//                updated_at: "2025-06-27T14:06:14.947659Z"
//            )
//        ],
//        isLoadingShimmer: true,  // Shimmer active
//        showAddButton: true,     // Button still visible
//        onAlertDeleted: { alert in
//            print("Alert deleted: \(alert.id)")
//        },
//        onNewAlertCreated: { alert in
//            print("New alert created: \(alert.id)")
//        },
//        onAlertUpdated: { alert in  // NEW: Added for preview
//            print("Alert updated: \(alert.id)")
//        }
//    )
//}

#Preview("Loading State - Button Hidden") {
    FAAlertView(
        alerts: [],
        isLoadingShimmer: false,
        showAddButton: false,  // Button hidden during initial load
        onAlertDeleted: { alert in
            print("Alert deleted: \(alert.id)")
        },
        onNewAlertCreated: { alert in
            print("New alert created: \(alert.id)")
        },
        onAlertUpdated: { alert in  // NEW: Added for preview
            print("Alert updated: \(alert.id)")
        }
    )
}
