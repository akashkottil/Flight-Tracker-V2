import SwiftUI

struct MyAlertsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLocationSheet = false
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                    }
                    Spacer()
                    Text("My alerts")
                        .bold()
                        .font(.title2)
                    Spacer()
                    // Empty view for balance
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding()
                .background(Color.white)
                
                // Alerts list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Alert cards
                        alertCard(
                            fromCode: "JFK",
                            fromName: "John F. Kennedy International Airport",
                            toCode: "COK",
                            toName: "Cochin International Airport"
                        )
                        
                        alertCard(
                            fromCode: "LAX",
                            fromName: "Los Angeles International Airport",
                            toCode: "COK",
                            toName: "Cochin International Airport"
                        )
                        
                        // Add extra padding at bottom to prevent content from being hidden behind the button
                        Color.clear
                            .frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                Button(action: {
                    showLocationSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add new alert")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                    .background(Color("FABlue"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            FALocationSheet()
        }
    }
    
    @ViewBuilder
    private func alertCard(fromCode: String, fromName: String, toCode: String, toName: String) -> some View {
        VStack(spacing: 0) {
            
            
            
            // From airport
            HStack(spacing: 15) {
                // Airport code badge
                VStack(alignment: .leading){
                    Text(fromCode)
                        .font(.system(size: 15, weight: .bold))
                        .padding(.vertical,5)
                        .cornerRadius(8)
                        Text(fromName)
                        .font(.system(size: 14))
                            .foregroundColor(.black)
                }
                
                
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        print("Delete alert")
                    }) {
                        Image("FADelete")
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    
                    Button(action: {
                        print("Edit alert")
                    }) {
                        Image("FAEdit")
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Arrow indicator
            HStack {
                Image("FADownArrow")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .padding(.vertical, 8)
                Spacer()
            }
            .padding(.horizontal,20)
            
            // To airport
            HStack(spacing: 15) {
                // Airport code badge
                VStack(alignment: .leading){
                    Text(toCode)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical,5)
                        .cornerRadius(8)
                        Text(toName)
                        .font(.system(size: 14))
                            .foregroundColor(.black)
                }
                
                Spacer()
                
                // Empty space to align with action buttons above
                Color.clear.frame(width: 60, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    MyAlertsView()
}
