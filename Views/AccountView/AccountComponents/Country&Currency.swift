import Foundation

// MARK: - Models
struct Country: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, code, flag
    }
}

struct Currency: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let symbol: String?
    let flag: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, code, symbol, flag
    }
}

// MARK: - Mock Data Service
class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    // MARK: - Countries Data
    private let mockCountries: [Country] = [
        // North America
        Country(name: "United States", code: "US", flag: "🇺🇸"),
        Country(name: "Canada", code: "CA", flag: "🇨🇦"),
        Country(name: "Mexico", code: "MX", flag: "🇲🇽"),
        
        // Europe
        Country(name: "United Kingdom", code: "GB", flag: "🇬🇧"),
        Country(name: "Germany", code: "DE", flag: "🇩🇪"),
        Country(name: "France", code: "FR", flag: "🇫🇷"),
        Country(name: "Spain", code: "ES", flag: "🇪🇸"),
        Country(name: "Italy", code: "IT", flag: "🇮🇹"),
        Country(name: "Netherlands", code: "NL", flag: "🇳🇱"),
        Country(name: "Switzerland", code: "CH", flag: "🇨🇭"),
        Country(name: "Sweden", code: "SE", flag: "🇸🇪"),
        Country(name: "Norway", code: "NO", flag: "🇳🇴"),
        Country(name: "Denmark", code: "DK", flag: "🇩🇰"),
        Country(name: "Finland", code: "FI", flag: "🇫🇮"),
        Country(name: "Belgium", code: "BE", flag: "🇧🇪"),
        Country(name: "Austria", code: "AT", flag: "🇦🇹"),
        Country(name: "Portugal", code: "PT", flag: "🇵🇹"),
        Country(name: "Greece", code: "GR", flag: "🇬🇷"),
        Country(name: "Poland", code: "PL", flag: "🇵🇱"),
        Country(name: "Czech Republic", code: "CZ", flag: "🇨🇿"),
        Country(name: "Hungary", code: "HU", flag: "🇭🇺"),
        Country(name: "Ireland", code: "IE", flag: "🇮🇪"),
        Country(name: "Iceland", code: "IS", flag: "🇮🇸"),
        
        // Asia
        Country(name: "India", code: "IN", flag: "🇮🇳"),
        Country(name: "China", code: "CN", flag: "🇨🇳"),
        Country(name: "Japan", code: "JP", flag: "🇯🇵"),
        Country(name: "South Korea", code: "KR", flag: "🇰🇷"),
        Country(name: "Singapore", code: "SG", flag: "🇸🇬"),
        Country(name: "Thailand", code: "TH", flag: "🇹🇭"),
        Country(name: "Vietnam", code: "VN", flag: "🇻🇳"),
        Country(name: "Indonesia", code: "ID", flag: "🇮🇩"),
        Country(name: "Malaysia", code: "MY", flag: "🇲🇾"),
        Country(name: "Philippines", code: "PH", flag: "🇵🇭"),
        Country(name: "Taiwan", code: "TW", flag: "🇹🇼"),
        Country(name: "Hong Kong", code: "HK", flag: "🇭🇰"),
        Country(name: "Bangladesh", code: "BD", flag: "🇧🇩"),
        Country(name: "Pakistan", code: "PK", flag: "🇵🇰"),
        Country(name: "Sri Lanka", code: "LK", flag: "🇱🇰"),
        Country(name: "Nepal", code: "NP", flag: "🇳🇵"),
        Country(name: "Myanmar", code: "MM", flag: "🇲🇲"),
        Country(name: "Cambodia", code: "KH", flag: "🇰🇭"),
        Country(name: "Laos", code: "LA", flag: "🇱🇦"),
        
        // Middle East
        Country(name: "United Arab Emirates", code: "AE", flag: "🇦🇪"),
        Country(name: "Saudi Arabia", code: "SA", flag: "🇸🇦"),
        Country(name: "Qatar", code: "QA", flag: "🇶🇦"),
        Country(name: "Kuwait", code: "KW", flag: "🇰🇼"),
        Country(name: "Bahrain", code: "BH", flag: "🇧🇭"),
        Country(name: "Oman", code: "OM", flag: "🇴🇲"),
        Country(name: "Israel", code: "IL", flag: "🇮🇱"),
        Country(name: "Jordan", code: "JO", flag: "🇯🇴"),
        Country(name: "Lebanon", code: "LB", flag: "🇱🇧"),
        Country(name: "Turkey", code: "TR", flag: "🇹🇷"),
        
        // Africa
        Country(name: "South Africa", code: "ZA", flag: "🇿🇦"),
        Country(name: "Nigeria", code: "NG", flag: "🇳🇬"),
        Country(name: "Kenya", code: "KE", flag: "🇰🇪"),
        Country(name: "Egypt", code: "EG", flag: "🇪🇬"),
        Country(name: "Morocco", code: "MA", flag: "🇲🇦"),
        Country(name: "Tunisia", code: "TN", flag: "🇹🇳"),
        Country(name: "Ghana", code: "GH", flag: "🇬🇭"),
        Country(name: "Ethiopia", code: "ET", flag: "🇪🇹"),
        Country(name: "Tanzania", code: "TZ", flag: "🇹🇿"),
        Country(name: "Uganda", code: "UG", flag: "🇺🇬"),
        
        // Oceania
        Country(name: "Australia", code: "AU", flag: "🇦🇺"),
        Country(name: "New Zealand", code: "NZ", flag: "🇳🇿"),
        Country(name: "Fiji", code: "FJ", flag: "🇫🇯"),
        
        // South America
        Country(name: "Brazil", code: "BR", flag: "🇧🇷"),
        Country(name: "Argentina", code: "AR", flag: "🇦🇷"),
        Country(name: "Chile", code: "CL", flag: "🇨🇱"),
        Country(name: "Colombia", code: "CO", flag: "🇨🇴"),
        Country(name: "Peru", code: "PE", flag: "🇵🇪"),
        Country(name: "Uruguay", code: "UY", flag: "🇺🇾"),
        Country(name: "Ecuador", code: "EC", flag: "🇪🇨"),
        Country(name: "Venezuela", code: "VE", flag: "🇻🇪"),
        
        // Others
        Country(name: "Russia", code: "RU", flag: "🇷🇺"),
        Country(name: "Ukraine", code: "UA", flag: "🇺🇦"),
        Country(name: "Belarus", code: "BY", flag: "🇧🇾"),
        Country(name: "Kazakhstan", code: "KZ", flag: "🇰🇿")
    ]
    
    // MARK: - Currencies Data
    private let mockCurrencies: [Currency] = [
        // Major Global Currencies
        Currency(name: "US Dollar", code: "USD", symbol: "$", flag: "🇺🇸"),
        Currency(name: "Euro", code: "EUR", symbol: "€", flag: "🇪🇺"),
        Currency(name: "British Pound", code: "GBP", symbol: "£", flag: "🇬🇧"),
        Currency(name: "Japanese Yen", code: "JPY", symbol: "¥", flag: "🇯🇵"),
        Currency(name: "Swiss Franc", code: "CHF", symbol: "Fr", flag: "🇨🇭"),
        
        // North American Currencies
        Currency(name: "Canadian Dollar", code: "CAD", symbol: "C$", flag: "🇨🇦"),
        Currency(name: "Mexican Peso", code: "MXN", symbol: "$", flag: "🇲🇽"),
        
        // Asian Currencies
        Currency(name: "Indian Rupee", code: "INR", symbol: "₹", flag: "🇮🇳"),
        Currency(name: "Chinese Yuan", code: "CNY", symbol: "¥", flag: "🇨🇳"),
        Currency(name: "South Korean Won", code: "KRW", symbol: "₩", flag: "🇰🇷"),
        Currency(name: "Singapore Dollar", code: "SGD", symbol: "S$", flag: "🇸🇬"),
        Currency(name: "Hong Kong Dollar", code: "HKD", symbol: "HK$", flag: "🇭🇰"),
        Currency(name: "Thai Baht", code: "THB", symbol: "฿", flag: "🇹🇭"),
        Currency(name: "Indonesian Rupiah", code: "IDR", symbol: "Rp", flag: "🇮🇩"),
        Currency(name: "Malaysian Ringgit", code: "MYR", symbol: "RM", flag: "🇲🇾"),
        Currency(name: "Philippine Peso", code: "PHP", symbol: "₱", flag: "🇵🇭"),
        Currency(name: "Vietnamese Dong", code: "VND", symbol: "₫", flag: "🇻🇳"),
        Currency(name: "Taiwan Dollar", code: "TWD", symbol: "NT$", flag: "🇹🇼"),
        Currency(name: "Bangladeshi Taka", code: "BDT", symbol: "৳", flag: "🇧🇩"),
        Currency(name: "Pakistani Rupee", code: "PKR", symbol: "Rs", flag: "🇵🇰"),
        Currency(name: "Sri Lankan Rupee", code: "LKR", symbol: "Rs", flag: "🇱🇰"),
        Currency(name: "Nepalese Rupee", code: "NPR", symbol: "Rs", flag: "🇳🇵"),
        
        // Middle Eastern Currencies
        Currency(name: "UAE Dirham", code: "AED", symbol: "د.إ", flag: "🇦🇪"),
        Currency(name: "Saudi Riyal", code: "SAR", symbol: "﷼", flag: "🇸🇦"),
        Currency(name: "Qatari Riyal", code: "QAR", symbol: "ر.ق", flag: "🇶🇦"),
        Currency(name: "Kuwaiti Dinar", code: "KWD", symbol: "د.ك", flag: "🇰🇼"),
        Currency(name: "Bahraini Dinar", code: "BHD", symbol: ".د.ب", flag: "🇧🇭"),
        Currency(name: "Omani Rial", code: "OMR", symbol: "ر.ع.", flag: "🇴🇲"),
        Currency(name: "Israeli Shekel", code: "ILS", symbol: "₪", flag: "🇮🇱"),
        Currency(name: "Jordanian Dinar", code: "JOD", symbol: "د.ا", flag: "🇯🇴"),
        Currency(name: "Lebanese Pound", code: "LBP", symbol: "ل.ل", flag: "🇱🇧"),
        Currency(name: "Turkish Lira", code: "TRY", symbol: "₺", flag: "🇹🇷"),
        
        // European Currencies (Non-Euro)
        Currency(name: "Norwegian Krone", code: "NOK", symbol: "kr", flag: "🇳🇴"),
        Currency(name: "Swedish Krona", code: "SEK", symbol: "kr", flag: "🇸🇪"),
        Currency(name: "Danish Krone", code: "DKK", symbol: "kr", flag: "🇩🇰"),
        Currency(name: "Polish Zloty", code: "PLN", symbol: "zł", flag: "🇵🇱"),
        Currency(name: "Czech Koruna", code: "CZK", symbol: "Kč", flag: "🇨🇿"),
        Currency(name: "Hungarian Forint", code: "HUF", symbol: "Ft", flag: "🇭🇺"),
        Currency(name: "Icelandic Krona", code: "ISK", symbol: "kr", flag: "🇮🇸"),
        Currency(name: "Russian Ruble", code: "RUB", symbol: "₽", flag: "🇷🇺"),
        Currency(name: "Ukrainian Hryvnia", code: "UAH", symbol: "₴", flag: "🇺🇦"),
        
        // African Currencies
        Currency(name: "South African Rand", code: "ZAR", symbol: "R", flag: "🇿🇦"),
        Currency(name: "Nigerian Naira", code: "NGN", symbol: "₦", flag: "🇳🇬"),
        Currency(name: "Kenyan Shilling", code: "KES", symbol: "KSh", flag: "🇰🇪"),
        Currency(name: "Egyptian Pound", code: "EGP", symbol: "£", flag: "🇪🇬"),
        Currency(name: "Moroccan Dirham", code: "MAD", symbol: "د.م.", flag: "🇲🇦"),
        Currency(name: "Tunisian Dinar", code: "TND", symbol: "د.ت", flag: "🇹🇳"),
        Currency(name: "Ghanaian Cedi", code: "GHS", symbol: "₵", flag: "🇬🇭"),
        Currency(name: "Ethiopian Birr", code: "ETB", symbol: "Br", flag: "🇪🇹"),
        
        // Oceanian Currencies
        Currency(name: "Australian Dollar", code: "AUD", symbol: "A$", flag: "🇦🇺"),
        Currency(name: "New Zealand Dollar", code: "NZD", symbol: "NZ$", flag: "🇳🇿"),
        Currency(name: "Fijian Dollar", code: "FJD", symbol: "FJ$", flag: "🇫🇯"),
        
        // South American Currencies
        Currency(name: "Brazilian Real", code: "BRL", symbol: "R$", flag: "🇧🇷"),
        Currency(name: "Argentine Peso", code: "ARS", symbol: "$", flag: "🇦🇷"),
        Currency(name: "Chilean Peso", code: "CLP", symbol: "$", flag: "🇨🇱"),
        Currency(name: "Colombian Peso", code: "COP", symbol: "$", flag: "🇨🇴"),
        Currency(name: "Peruvian Sol", code: "PEN", symbol: "S/", flag: "🇵🇪"),
        Currency(name: "Uruguayan Peso", code: "UYU", symbol: "$U", flag: "🇺🇾")
    ]
    
    // MARK: - Public Methods
    
    /// Get all countries
    func getAllCountries() -> [Country] {
        return mockCountries
    }
    
    /// Get all currencies
    func getAllCurrencies() -> [Currency] {
        return mockCurrencies
    }
    
    /// Search countries by name or code
    func searchCountries(query: String) -> [Country] {
        if query.isEmpty {
            return mockCountries
        }
        return mockCountries.filter { country in
            country.name.localizedCaseInsensitiveContains(query) ||
            country.code.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Search currencies by name, code, or symbol
    func searchCurrencies(query: String) -> [Currency] {
        if query.isEmpty {
            return mockCurrencies
        }
        return mockCurrencies.filter { currency in
            currency.name.localizedCaseInsensitiveContains(query) ||
            currency.code.localizedCaseInsensitiveContains(query) ||
            (currency.symbol?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    /// Find country by code
    func findCountry(byCode code: String) -> Country? {
        return mockCountries.first { $0.code.lowercased() == code.lowercased() }
    }
    
    /// Find currency by code
    func findCurrency(byCode code: String) -> Currency? {
        return mockCurrencies.first { $0.code.lowercased() == code.lowercased() }
    }
    
    /// Get popular countries (top 20 most commonly used)
    func getPopularCountries() -> [Country] {
        let popularCodes = ["US", "IN", "GB", "CA", "AU", "DE", "FR", "JP", "KR", "CN",
                           "SG", "AE", "BR", "MX", "ES", "IT", "NL", "CH", "SE", "NO"]
        return popularCodes.compactMap { code in
            findCountry(byCode: code)
        }
    }
    
    /// Get popular currencies (top 15 most commonly used)
    func getPopularCurrencies() -> [Currency] {
        let popularCodes = ["USD", "EUR", "GBP", "JPY", "INR", "CAD", "AUD", "CHF",
                           "CNY", "KRW", "SGD", "AED", "BRL", "MXN", "HKD"]
        return popularCodes.compactMap { code in
            findCurrency(byCode: code)
        }
    }
    
    /// Get countries by region
    func getCountriesByRegion() -> [String: [Country]] {
        return [
            "North America": searchCountries(query: "").filter { ["US", "CA", "MX"].contains($0.code) },
            "Europe": searchCountries(query: "").filter { ["GB", "DE", "FR", "ES", "IT", "NL", "CH", "SE", "NO", "DK", "FI", "BE", "AT", "PT", "GR", "PL", "CZ", "HU", "IE", "IS"].contains($0.code) },
            "Asia": searchCountries(query: "").filter { ["IN", "CN", "JP", "KR", "SG", "TH", "VN", "ID", "MY", "PH", "TW", "HK", "BD", "PK", "LK", "NP", "MM", "KH", "LA"].contains($0.code) },
            "Middle East": searchCountries(query: "").filter { ["AE", "SA", "QA", "KW", "BH", "OM", "IL", "JO", "LB", "TR"].contains($0.code) },
            "Africa": searchCountries(query: "").filter { ["ZA", "NG", "KE", "EG", "MA", "TN", "GH", "ET", "TZ", "UG"].contains($0.code) },
            "Oceania": searchCountries(query: "").filter { ["AU", "NZ", "FJ"].contains($0.code) },
            "South America": searchCountries(query: "").filter { ["BR", "AR", "CL", "CO", "PE", "UY", "EC", "VE"].contains($0.code) }
        ]
    }
}
