

import SwiftUI

struct ResultCard:View {
    var body: some View {
        VStack(alignment: .leading){
//            tags
            HStack{
                Text("Best")
                    .padding(.vertical,4)
                    .padding(.horizontal,15)
                    .foregroundColor(Color.white)
                    .background(Color.purple)
                    .cornerRadius(15)
//                    .font(.)
                Text("Cheapest")
                    .padding(.vertical,6)
                    .padding(.horizontal,20)
                    .foregroundColor(Color.white)
                    .background(Color.green)
                    .cornerRadius(15)
                    .font(.caption)
                Text("Fastest")
                    .padding(.vertical,6)
                    .padding(.horizontal,20)
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .font(.caption)
                    
            }
//            direct
            HStack{
                HStack{
    //                leftside time
                    VStack{
    //                    time and logo
                        HStack{
                            Image("depLogo")
                            Text("17:10")
                        }
    //                    date and destination
                        
                        Text("COK • 10 APR")
                            .font(.caption)
                            
                    }
                }
                Spacer()
                HStack{
                    Text("12h 30m")
                }
                .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .fontWeight(.medium)
                                    .font(.caption)
                Spacer()
                
                HStack{
    //                right side time
                    VStack{
    //                    time and logo
                        HStack{
                            
                            Text("17:10")
                        }
    //                    date and destination
                        Text("COK • 10 APR")
                            .font(.caption)
                    }
                }
            }
            
//            1 stop
            
            HStack{
                HStack{
    //                leftside time
                    VStack{
    //                    time and logo
                        HStack{
                            Image("depLogo")
                            Text("17:10")
                        }
    //                    date and destination
                        Text("COK • 10 APR")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                HStack{
                    HStack{
                        Text("12h 30m")
                    }
                    .foregroundColor(Color.black.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .fontWeight(.medium)
                                        .font(.caption)
                }
                
                
                Spacer()
                
                HStack{
    //                right side time
                    VStack{
    //                    time and logo
                        HStack{
                            
                            Text("17:10")
                        }
    //                    date and destination
                        Text("COK • 10 APR")
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            HStack{
                Text("Qatar Airways & 2 others")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
                VStack(alignment:.trailing){
                    Text("₹ 2,546")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("For 2 People  ₹5232")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.8))
                }
            }
//            .padding(.horizontal, 20)
            
            
            
        }
        .padding()
        .background(Color.white)
        .padding(.horizontal, 20)
        
    }
}

#Preview {
    ResultCard()
}
