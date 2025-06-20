import SwiftUI

struct TrackedDetailsScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView(title: "COK - LON 12 Jun") {
                dismiss()
            }
            
            // Main Content
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        TrackFlightCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
    }
}

struct CustomHeaderView: View {
    let title: String
    let onBackTap: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header background with proper safe area
                ZStack {
                    // Dark blue background extending to top
                    Color(red: 0.15, green: 0.25, blue: 0.45)
                        .ignoresSafeArea(edges: .top)
                    
                    VStack {
//                        Spacer()
                        
                        // Header content
                        HStack(spacing: 0) {
                            // Back button
                            Button(action: onBackTap) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
//                            Spacer()
                            
                            // Title with rounded white background
//                            HStack {
//                                Text(title)
//                                    .font(.system(size: 16, weight: .medium))
//                                    .foregroundColor(.black)
//                                    .padding(.horizontal, 24)
//                                    .padding(.vertical, 10)
//                                    .background(
//                                        Capsule()
//                                            .fill(Color.white)
//                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//                                    )
//                            }
                            
                            Spacer()
                            
                            // Invisible spacer to balance layout
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(height: geometry.safeAreaInsets.top + 20)
            }
        }
        .frame(height: 10) // Total header height
    }
}

struct TrackFlightCard: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header with airline info and status
            HStack {
                HStack(spacing: 8) {
                    // Airline logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        
                        Text("6E")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Indigo • 6E 6083")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Status badge
                Text("Scheduled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Flight details
            HStack(alignment: .center, spacing: 0) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text("17:10")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text("COK")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("10 Apr")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Flight path visualization
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("12h 10m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Arrival
                VStack(alignment: .trailing, spacing: 4) {
                    Text("18:30")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text("CNN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("10 Apr")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Direct flight indicator
            HStack {
                Text("Direct")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct TrackedDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        TrackedDetailsScreen()
    }
}
