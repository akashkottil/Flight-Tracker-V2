
import SwiftUI

struct BottomSignature: View{
    var body: some View{
        HStack{
            VStack(alignment:.leading){
                VStack(alignment: .leading){
                    Text("Where to")
                    Text("next?")
                }
                    .font(.system(size: 38))
                    .fontWeight(.heavy)
                    .foregroundStyle(.gray.opacity(0.7))
                
                HStack{
                    Image("BottomLogo")
                    Text("All Flights")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray.opacity(0.7))
                }
                
            }
            Spacer()
            
        }
        .padding()
        .padding(.horizontal)
        .padding(.bottom, 20)
        
    }
}


#Preview {
    BottomSignature()
}
