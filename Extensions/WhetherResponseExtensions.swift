//// Add this extension to your WeatherResponse file or create a new file
//
//extension WeatherResponse.Current {
//    
//    // Computed property to get weather condition text
//    var weatherCondition: String {
//        return getWeatherInfo(code: weatherCode, isDay: isDay).condition
//    }
//    
//    // Computed property to get weather icon name
//    var weatherIcon: String {
//        return getWeatherInfo(code: weatherCode, isDay: isDay).icon
//    }
//    
//    // Main function to map weather codes to condition and icon
//    private func getWeatherInfo(code: Int, isDay: Int?) -> (condition: String, icon: String) {
//        let isDayTime = isDay != 0
//        
//        switch code {
//        case 0:
//            return ("Clear sky", isDayTime ? "clear_sun" : "clear_moon")
//            
//        case 1:
//            return ("Mainly clear", isDayTime ? "clear_sun" : "clear_moon")
//            
//        case 2:
//            return ("Partly cloudy", isDayTime ? "few_clouds_sun" : "few_cloud_moon")
//            
//        case 3:
//            return ("Overcast", "broken_clouds")
//            
//        case 45:
//            return ("Fog", "mist")
//            
//        case 48:
//            return ("Depositing rime fog", "mist")
//            
//        case 51:
//            return ("Light drizzle", "shower_rain")
//            
//        case 53:
//            return ("Moderate drizzle", "shower_rain")
//            
//        case 55:
//            return ("Dense drizzle", "shower_rain")
//            
//        case 56:
//            return ("Light freezing drizzle", "shower_rain")
//            
//        case 57:
//            return ("Dense freezing drizzle", "shower_rain")
//            
//        case 61:
//            return ("Slight rain", isDayTime ? "rain_sun" : "rain_moon")
//            
//        case 63:
//            return ("Moderate rain", isDayTime ? "rain_sun" : "rain_moon")
//            
//        case 65:
//            return ("Heavy rain", isDayTime ? "rain_sun" : "rain_moon")
//            
//        case 66:
//            return ("Light freezing rain", isDayTime ? "rain_sun" : "rain_moon")
//            
//        case 67:
//            return ("Heavy freezing rain", isDayTime ? "rain_sun" : "rain_moon")
//            
//        case 71:
//            return ("Slight snow fall", "snow")
//            
//        case 73:
//            return ("Moderate snow fall", "snow")
//            
//        case 75:
//            return ("Heavy snow fall", "snow")
//            
//        case 77:
//            return ("Snow grains", "snow")
//            
//        case 80:
//            return ("Slight rain showers", "shower_rain")
//            
//        case 81:
//            return ("Moderate rain showers", "shower_rain")
//            
//        case 82:
//            return ("Violent rain showers", "shower_rain")
//            
//        case 85:
//            return ("Slight snow showers", "snow")
//            
//        case 86:
//            return ("Heavy snow showers", "snow")
//            
//        case 95:
//            return ("Thunderstorm", "thunderstorm")
//            
//        case 96:
//            return ("Thunderstorm with slight hail", "thunderstorm")
//            
//        case 99:
//            return ("Thunderstorm with heavy hail", "thunderstorm")
//            
//        default:
//            return ("Clear sky", isDayTime ? "clear_sun" : "clear_moon")
//        }
//    }
//}
//
//// MARK: - Usage in Views
//// To use in SwiftUI:
//// Image(weather.current.weatherIcon)
////     .resizable()
////     .frame(width: 50, height: 50)
////
//// Text(weather.current.weatherCondition)
//
//// To use in UIKit:
//// imageView.image = UIImage(named: weather.current.weatherIcon)
//// label.text = weather.current.weatherCondition
