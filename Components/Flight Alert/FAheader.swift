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
        }
    }
}


#Preview {
    FAheader()
}
