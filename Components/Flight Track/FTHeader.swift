import SwiftUI

struct FTHeader: View {
    let departureCity: String
    let arrivalCity: String
    let date: String
    let onBackTap: () -> Void
    let onShareTap: () -> Void
    
    var body: some View {
        VStack{
            HStack{
                Button(action: onBackTap) {
                    Image("FliterBack")
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(departureCity) - \(arrivalCity)")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(date)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: onShareTap) {
                    Image("FilterShare")
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(GradientColor.FTHGradient)
    }
}
