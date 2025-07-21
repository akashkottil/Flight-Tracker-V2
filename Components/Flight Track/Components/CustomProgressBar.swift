//
//  CustomProgressBar.swift
//  AllFlights
//
//  Created by Akash Kottil on 21/07/25.
//
import SwiftUI

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
