import SwiftUI

struct FADelete: View {
    let alertToDelete: AlertResponse?
    let onDelete: () -> Void
    let onCancel: () -> Void
    let isDeleting: Bool
    
    init(
        alertToDelete: AlertResponse? = nil,
        onDelete: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        isDeleting: Bool = false
    ) {
        self.alertToDelete = alertToDelete
        self.onDelete = onDelete
        self.onCancel = onCancel
        self.isDeleting = isDeleting
    }
    
    var body: some View {
        ZStack{
            VStack(alignment: .leading, spacing: 20){
                Spacer()
                
                Image("FADeleteImg")
                    .frame(width: 80, height: 80)
                
                Text("Delete Alert?")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                
                Text(deleteMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                VStack(spacing: 12) {
                    // Delete Button
                    Button(action: {
                        if !isDeleting {
                            onDelete()
                        }
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                                    .fontWeight(.bold)
                            } else {
                                Text("Delete")
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GradientColor.DeleteRed)
                        )
                    }
                    .disabled(isDeleting)
                    
                    // Cancel Button
                    Button(action: {
                        if !isDeleting {
                            onCancel()
                        }
                    }) {
                        HStack {
                            Text("Cancel")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.clear)
                                .overlay(
                                    GradientColor.DeleteRed
                                        .mask(
                                            Text("Cancel")
                                                .fontWeight(.bold)
                                                .frame(width: 332, height: 52)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .disabled(isDeleting)
                }
                
//                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical,50)
            .frame(maxWidth: .infinity)
        }
        
        .ignoresSafeArea()
        .background(
            GradientColor.transparentWhite
        )
    }
    
    private var deleteMessage: String {
        if let alert = alertToDelete {
            return "Are you sure you want to delete the alert for \(alert.route.origin_name) → \(alert.route.destination_name)? This action cannot be undone."
        } else {
            return "Are you sure you want to delete this alert? This action cannot be undone."
        }
    }
}

#Preview {
    FADelete(
        alertToDelete: AlertResponse(
            id: "sample-id-1",
            user: AlertUserResponse(
                id: "testId",
                push_token: "token",
                created_at: "2025-06-27T14:06:14.919574Z",
                updated_at: "2025-06-27T14:06:14.919604Z"
            ),
            route: AlertRouteResponse(
                id: 151,
                origin: "JFK",
                destination: "COK",
                currency: "USD",
                origin_name: "John F. Kennedy International Airport",
                destination_name: "Cochin International Airport",
                created_at: "2025-06-25T09:32:47.398234Z",
                updated_at: "2025-06-27T14:06:14.932802Z"
            ),
            cheapest_flight: CheapestFlight(
                id: 13599,
                price: 699,
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
        onDelete: {
            print("Delete button tapped")
        },
        onCancel: {
            print("Cancel button tapped")
        },
        isDeleting: false
    )
}
