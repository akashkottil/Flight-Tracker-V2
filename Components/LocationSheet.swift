import SwiftUI
import CoreLocation

struct LocationSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var isOrigin: Bool
    var onLocationSelected: (AutocompleteItem) -> Void
    
    @StateObject private var viewModel = AutocompleteViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: {
                    dismiss() // Dismiss the sheet
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                Spacer()
                Text(isOrigin ? "From Where?" : "To Where?")
                    .bold()
                    .font(.title2)
                Spacer()
                // Empty view for balance
                Color.clear.frame(width: 40, height: 40)
            }
            .padding()
            
            // Search field - only show the relevant one
            HStack {
                TextField(isOrigin ? "Origin City, Airport or place" : "Destination City, Airport or place",
                          text: $viewModel.searchText)
                    .padding()
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top)
            
            // Use current location button - only show for origin selection
            if isOrigin {
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Use Current Location")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        if locationManager.isLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                }
                .disabled(locationManager.isLoading)
            }
            
            // Display any location errors
            if let error = locationManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Divider
            Divider()
                .padding(.horizontal)
            
            // Results list or loading indicator
            if viewModel.isLoading || locationManager.isLoading {
                ProgressView()
                    .padding()
                Spacer()
            } else {
                // Current location result if available
                if isOrigin, let placemark = locationManager.placemark, let locationItem = locationManager.createAutoCompleteItem() {
                    Button(action: {
                        onLocationSelected(locationItem)
                        dismiss()
                    }) {
                        VStack(spacing: 0) {
                            HStack(spacing: 15) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Location")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("\(placemark.locality ?? ""), \(placemark.country ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            
                            Divider().padding(.leading, 60)
                        }
                    }
                    .contentShape(Rectangle())
                }
                
                // Search results
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.results) { item in
                            locationResultRow(item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onLocationSelected(item)
                                    dismiss()
                                }
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .onChange(of: locationManager.placemark) { newValue in
            if let newValue = newValue, let autoCompleteItem = locationManager.createAutoCompleteItem() {
                // If the user explicitly requested current location, select it automatically
                if locationManager.isLoading == false {
                    onLocationSelected(autoCompleteItem)
                    dismiss()
                }
            }
        }
    }
    
    @ViewBuilder
    private func locationResultRow(_ item: AutocompleteItem) -> some View {
        HStack(spacing: 15) {
            // Airport code badge
            Text(item.iataCode)
                .font(.system(size: 14, weight: .medium))
                .padding(8)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Main location name
                Text("\(item.cityName), \(item.countryName)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                // Subtitle with airport name
                Text(item.airportName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
