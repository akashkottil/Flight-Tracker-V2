import SwiftUI

struct FeatureCards: View {
    @StateObject private var sharedSearchData = SharedSearchDataStore.shared
    
    var body: some View {
        HStack {
            // Explore Card
            HStack {
                VStack(alignment: .leading) {
                    Image("trackFlight")
                    Text("Explore")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppPrimaryColor"))
                        .padding(.top,4)
                    Text("Destinations")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(Color("AppPrimaryColor"))
                }
                .padding(.leading, 30)
                Spacer()
            }
            .frame(width: 180, height: 136)
            .background(Color.blue.opacity(0.06))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color("AppPrimaryColor"), lineWidth: 1)
            )
            .onTapGesture {
                // Navigate to Explore tab (tag 2)
                sharedSearchData.navigateToTab(2)
            }
            
            Spacer()
            
            // Track Flight Card
            HStack {
                VStack(alignment: .leading) {
                    Image("exploreFlight")
                    Text("Track")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppPrimaryColor"))
                        .padding(.top,4)
                    Text("your Flights") // Fixed typo
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(Color("AppPrimaryColor"))
                }
                .padding(.leading, 30)
                Spacer()
            }
            .frame(width: 180, height: 136)
            .background(Color.purple.opacity(0.06))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(.purple), lineWidth: 1)
            )
            .onTapGesture {
                // Navigate to Flight Tracker tab (tag 3)
                sharedSearchData.navigateToTab(3)
            }
        }
        .padding()
    }
}

#Preview {
    FeatureCards()
}
