//
//  LoginNotifier.swift
//  all-flights
//
//  Created by Akash Kottill on 14/05/25.
//

import SwiftUI

struct LoginNotifier: View {
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                Text("Get notified before fare drop")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                Text("Lorem ipsum dolor sit amet ")
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)
                Button(action: {}) {
                    Text("Login")
                        .foregroundColor(.white)
                        .padding(.vertical,10)
                        .padding(.horizontal,20)
                        .background(Color("buttonBlue"))
                        .cornerRadius(8)
                        .font(.system(size: 14))
                }
                .frame(width: 80, height: 44, alignment: .center)
            }
//            .padding(.leading,20)
            Spacer()
            VStack{
                Image("messageImg")
            }
//            .padding(.trailing,20)
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.6), lineWidth: 2)
        )
        .cornerRadius(20)
        .padding()
    }
}


#Preview {
    LoginNotifier()
}
