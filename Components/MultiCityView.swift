import SwiftUI

struct MultiCityView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<viewModel.trips.count, id: \.self) { index in
                singleTripSection(for: index)
                    .background(Color.white)
                    .overlay(
                        HStack {
                            Spacer()
                            // Only show remove button when there's more than one city
                            if viewModel.trips.count > 1 {
                                Button(action: {
                                    viewModel.removeTrip(at: index)
                                }) {
                                    Text("Remove")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .padding(.trailing)
                                .padding(.top, 5)
                            }
                        }
                    )
            }
            
            // Add flight button
            Button(action: {
                viewModel.addTrip()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Add flight")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func singleTripSection(for index: Int) -> some View {
        VStack(spacing: 0) {
            // Origin
            LocationItem(
                icon: "airplane.departure",
                code: viewModel.trips[index].originCode,
                city: viewModel.trips[index].originCity,
                showRemoveButton: false,
                action: { viewModel.openLocationSheet(isOrigin: true, tripIndex: index) }
            )
            
            Divider().padding(.leading, 50)
//                .overlay(
//                    // Swap button for multi-city
//                    Button(action: {
//                        viewModel.swapOriginAndDestination(for: index)
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
            
            // Destination
            LocationItem(
                icon: "airplane.arrival",
                code: viewModel.trips[index].destinationCode,
                city: viewModel.trips[index].destinationCity,
                showRemoveButton: false,
                action: { viewModel.openLocationSheet(isOrigin: false, tripIndex: index) }
            )
            
            Divider().padding(.leading, 50)
            
            // Date
            HStack {
                Image("CalendarIcon")
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                Text(viewModel.formatSingleDate(viewModel.trips[index].date))
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            
            Divider().padding(.leading, 50)
        }
    }
}



