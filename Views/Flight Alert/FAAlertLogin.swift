import SwiftUI

struct FFAAlertLogin: View {
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
                
                Image("FALoginImg")
                    .frame(width: 80, height: 80)
                
                Text("Login to get alerts")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                
                Text("Access your profile, manage settings, and view personalized features.")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                VStack(spacing: 12) {
//                    google signin button
                    Button(action: {
//                        google signin action
                    }) {
                        HStack {
                            HStack{
                                Image("FAGoogle")
                                Spacer()
                                Text("Sign in with Google")
                                    .fontWeight(.regular)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("FABlueLight"))
                        )
                    }
                    
                    
//                    apple signin
                    Button(action: {
//                        google signin action
                    }) {
                        HStack {
                            HStack{
                                Image("FAApple")
                                Spacer()
                                Text("Sign in with Apple")
                                    .fontWeight(.regular)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("FABlueLight"))
                        )
                    }
                    

                    
                    // Cancel Button
                    Button(action: {
//                       Maybe Later button
                    }) {
                        HStack {
                            Text("Maybe later")
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.clear)
                                .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                        }
                    }
                    
                    HStack{
//                        add check box here
                        Text("By creating or logging into an account you’re agreeing with our ")
                        + Text("terms and conditions")
                            .bold()
                        + Text(" and ")
                        + Text("privacy statement")
                            .bold()

                    }
                    .foregroundColor(.black.opacity(0.7))
                    .font(.system(size: 14))
                    
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
}


#Preview {
    FFAAlertLogin(
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
