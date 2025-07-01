import SwiftUI
struct FAheader: View {
    var body: some View {
        VStack{
            HStack{
                Image("FALogoWhite")
                Spacer()
                HStack{
                    Image("FAPassenger")
                    Text("1")
                }
                .padding(.vertical,8)
                .padding(.horizontal,10)
                .background(.white)
                .cornerRadius(10)
            }
            
            .padding(.horizontal,10)
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's price drop alerts")
                        .font(.system(size: 20, weight: .bold))
                    Text("Real-time flight price monitoring")
                        .font(.system(size: 14, weight: .regular))
                }
                Spacer()
            }
            .padding(.horizontal, 20)

        }
    }
}


#Preview {
    FAheader()
}
