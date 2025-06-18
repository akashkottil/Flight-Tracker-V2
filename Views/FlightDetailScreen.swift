import SwiftUI

struct FlightDetailScreen: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // Flight Info Header
                    VStack {
                        HStack{
                            Image("FlightTrackLogo") // Placeholder for airline icon
                                .resizable()
                                .frame(width: 34, height: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("6E 6082")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Indigo")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("Scheduled")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.rainForest) // Use your custom color
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.rainForest, lineWidth: 1)
                                )

                            
                        }
                        
                        Image("DottedLine")
//                            .frame(width: .infinity)
       
                        // Flight Route Timeline with updated design
                        HStack(alignment: .top, spacing: 16) {
                            // Timeline positioned to align with airport codes
                            VStack(spacing: 0) {
                                // Spacing for alignment
                                Spacer()
//                                    .frame(height: 42)
                                // Departure circle
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                                    .frame(width: 8, height: 8)
                                // Connecting line
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(width: 1, height: 120)
                                    .padding(.top, 4)
                                    .padding(.bottom, 4)
                                // Arrival circle
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                                    .frame(width: 8, height: 8)
                                // Space for remaining content
                                Spacer()
                            }
                            
                            // Flight details
                            VStack(alignment: .leading, spacing: 10) {
                                // Departure
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("COK")
                                                .font(.system(size: 34, weight: .bold))
                                               
                                            Text("Kochi International Airport")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                            Text("Terminal: T4 • Gate: 4A")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("09:32")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.rainForest)
                                            Text("Ontime")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.rainForest)
                                            Text("15 May, Wed")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                // Duration (centered between departure and arrival)
                                HStack {
                                    Spacer()
                                    Text("2h 10min")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                
                                // Arrival
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("DEL")
                                                .font(.system(size: 34, weight: .bold))
                                                .fontWeight(.bold)
                                            Text("Indira Gandhi Airport")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                            Text("Terminal: T4 • Gate: --")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("12:32")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.rainForest)
                                            Text("Ontime")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.rainForest)
                                            Text("15 May, Wed")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        .padding()
                        
                        Divider()
                            .padding(.bottom,20)
                        
                        // Status Cards
                        VStack(spacing: 12) {
                            flightStatusCard(title: "Kochi, India", gateTime: "2:00 PM", estimatedGateTime: "2:00 PM", gateStatus: "On time", runwayTime: "2:00 PM", runwayStatus: "1m delayed")
                            
                            Divider()
                                .padding(.vertical,20)
                            
                            flightStatusCard(title: "Delhi, India", gateTime: "4:50 PM", estimatedGateTime: nil, gateStatus: "On time", runwayTime: "Unavailable", runwayStatus: "Unavailable")
                        }
                        
//
                        
                        
                        AirlinesInfo()
                        
                        AboutDestination()
                        
                        // Notification & Delete
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Notification")
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                                Toggle("", isOn: .constant(false))
                                    .labelsHidden()
                            }
                            Divider()
                            HStack {
                                Text("Add to Calendar")
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                                Toggle("", isOn: .constant(false))
                                    .labelsHidden()
                            }
                            Divider()
                            HStack {
                                Button(action: {
                                    // delete action
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Delete")
                                            .foregroundColor(.red)
                                            .font(.system(size: 18, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1.4)
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)


                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
                    
//                    Text("Updated just now")
//                        .font(.system(size: 12))
//                        .fontWeight(.semibold)
//                        .foregroundColor(.rainForest)

                   
//                    // Weather Info
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Good to Know")
//                            .font(.system(size: 16))
//                            .fontWeight(.bold)
//                        Text("Information about your destination")
//                            .font(.system(size: 14))location
//                            .fontWeight(.semibold)
//                            .foregroundColor(.gray)
//                        HStack {
//                            VStack(alignment: .leading) {
//                                Text("29°C")
//                                    .font(.system(size: 26))
//                                    .bold()
//                                
//                                Text("Might rain in New Delhi")
//                                    .font(.system(size: 14))
//                                    .fontWeight(.semibold)
//                            }
//
//                            
//
//                            Spacer()
//                            Image("Cloud")
//                                .frame(width: 64, height: 58)
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(12)
//                    .shadow(color: Color.black.opacity(0.05), radius: 4)

                    
                }
//                .padding(.bottom,30)
//                .background(Color(.systemGroupedBackground))
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0C243E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("FliterBack")
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Kochi - Delhi")
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        Text("28 Jan, 2024")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share action
                    }) {
                        Image("FilterShare")
                    }
                }
            }
        }
    }

    private func flightStatusCard(title: String, gateTime: String, estimatedGateTime: String?, gateStatus: String, runwayTime: String, runwayStatus: String) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header with plane icon and city
                HStack(spacing: 12) {
                    Image(systemName: title.contains("Kochi") ? "airplane.departure" : "airplane.arrival")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(title.contains("Kochi") ? "Departure" : "Arrival")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // Gate Time section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gate Time")
                        .font(.system(size: 18, weight: .semibold))
                    
                    // Three columns layout
                    HStack(spacing: 0) {
                        // Scheduled column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(gateTime)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Estimated column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Estimated")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(estimatedGateTime ?? "-")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Status column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Status")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(gateStatus)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(gateStatus.lowercased().contains("time") ? .green : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                }
                
                // Runway Time section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Runway Time")
                        .font(.system(size: 18, weight: .semibold))
                    
                    // Three columns layout
                    HStack(spacing: 0) {
                        // Scheduled column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(runwayTime)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Estimated column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Estimated")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("-")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Status column
                        VStack(alignment: .center, spacing: 8) {
                            Text("Status")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(runwayStatus)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(runwayStatus.contains("delayed") ? .red : runwayStatus.lowercased().contains("time") ? .green : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                }
            }
//            .padding(16)
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(color: Color.black.opacity(0.05), radius: 4)
        
        }
}

struct AirlinesInfo: View {
    var body: some View {
        VStack(alignment:.leading, spacing: 12){
            Text("Airline Information")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 15)
            HStack{
                Image("FlightTrackLogo")
                    .frame(width: 34, height: 34)
                Text("Indigo Airlines")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            HStack{
                VStack {
                    Text("ATC Callsign")
                    Text("Indigo")
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack {
                    Text("ATC Callsign")
                    Text("Indigo")
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack {
                    Text("ATC Callsign")
                    Text("Indigo")
                        .fontWeight(.bold)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            }
            Text("Flight performance")
                .font(.system(size: 16, weight: .semibold))
            HStack{
                Text("On-time")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("90%")
                    .font(.system(size: 12, weight: .bold))
            }
            // Custom Progress Bar
                            CustomProgressBar(progress: 0.9) // 90%
                                .padding(.vertical, 4)
            
            Text("Based on data for the past 10 days")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

struct AboutDestination: View {
    var body: some View {
        VStack(alignment: .leading){
            Text("About your destination")
                .font(.system(size: 18, weight: .semibold))
            HStack{
                VStack(alignment: .leading){
                    Text("29°C")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Might rain in New Delhi")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image("Cloud")
            }
            .padding()
            .background(.blue)
            .cornerRadius(20)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Timezone change")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                    Text("+1h 39 min")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.black)
                    Text("Arrival at 18:00 Wed,30 May is 19:39 at Kochi")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1.4)
            )
            .cornerRadius(20)

        }
        
    }
}


struct CustomProgressBar: View {
    let progress: Double // Value between 0.0 and 1.0
    let height: CGFloat = 8
    let cornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (wrapped box)
                RoundedRectangle(cornerRadius: cornerRadius*2)
                    .fill(Color(red: 0.827, green: 0.827, blue: 0.827, opacity: 0.4)) // #D3D3D366
                    .frame(height: height*2)
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.0, green: 0.424, blue: 0.890)) // #006CE3
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .padding(.horizontal,5)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    FlightDetailScreen()
}
