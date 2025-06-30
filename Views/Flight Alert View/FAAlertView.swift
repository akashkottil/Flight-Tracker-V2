import SwiftUI

struct FAAlertView : View {
    
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    var body: some View {
        ZStack {
            GradientColor.BlueWhite
                .ignoresSafeArea()
            VStack {
                FAheader()
                
//                if there is no alert then show NoAlert() component inside Vstack. hide the ScrollView that contain heading and FACard()
                
                ScrollView {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's price drop alerts")
                                .font(.system(size: 20, weight: .bold))
                            Text("Price dropped by at least 30%")
                                .font(.system(size: 14, weight: .regular))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    FACard()
                        .padding()
                    Color.clear
                        .frame(height: 80)
                }
            }
            
            // Fixed bottom button
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
                }
                .foregroundColor(.white)
                .font(.system(size: 18))
                .background(Color("FABlue"))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            FALocationSheet()
        }
        .sheet(isPresented: $showMyAlertsSheet) {
            MyAlertsView()
        }
    }
}


#Preview {
    FAAlertView()
}

