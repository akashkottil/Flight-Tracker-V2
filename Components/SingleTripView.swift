import SwiftUI

struct SingleTripView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Origin location selector
            LocationItem(
                icon: "airplane.departure",
                code: viewModel.originCode,
                city: viewModel.originCity,
                showRemoveButton: false,
                action: { viewModel.openLocationSheet(isOrigin: true) }
            )
            
            Divider().padding(.leading, 50)
//                .overlay(
//                    // Swap button for return trips
//                    Button(action: {
//                        viewModel.swapOriginAndDestination()
//                    }) {
//                        Image(systemName: "arrow.up.arrow.down")
//                            .foregroundColor(.blue)
//                            .padding(8)
//                            .background(Circle().fill(Color.white))
//                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
//                    }
//                    .offset(y: -2), // Position slightly above the divider
//                    alignment: .center
//                )
            
            if viewModel.tripType == .returnTrip {
                // Destination location selector
                LocationItem(
                    icon: "airplane.arrival",
                    code: viewModel.destinationCode,
                    city: viewModel.destinationCity,
                    showRemoveButton: false,
                    action: { viewModel.openLocationSheet(isOrigin: false) }
                )
                
                Divider().padding(.leading, 50)
            }
            
            // Date selector
            HStack {
                Image("CalendarIcon")
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                if viewModel.tripType == .returnTrip {
                    Text(viewModel.formatDateRange())
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                } else {
                    Text(viewModel.formatSingleDate(viewModel.startDate))
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
        }
    }
}
