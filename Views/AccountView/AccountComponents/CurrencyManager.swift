import Foundation
import Combine

// MARK: - Shared Currency Manager
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var selectedCurrency: Currency? {
        didSet {
            saveCurrency()
            // Notify about currency change
            NotificationCenter.default.post(name: .currencyChanged, object: nil)
        }
    }
    
    @Published var selectedCountry: Country? {
        didSet {
            saveCountry()
            // Notify about country change
            NotificationCenter.default.post(name: .countryChanged, object: nil)
        }
    }
    
    // Current currency info from API responses
    @Published var currentCurrencyInfo: CurrencyDetail?
    
    private let userDefaults = UserDefaults.standard
    private let currencyKey = "SelectedCurrency"
    private let countryKey = "SelectedCountry"
    
    private init() {
        loadSavedSelections()
    }
    
    // MARK: - Currency Code and Country Code for API
    var currencyCode: String {
        return selectedCurrency?.code ?? "INR"
    }
    
    var countryCode: String {
        return selectedCountry?.code ?? "IN"
    }
    
    // MARK: - Price Formatting
    func formatPrice(_ price: Double) -> String {
        let intPrice = Int(price)
        return formatPrice(intPrice)
    }
    
    func formatPrice(_ price: Int) -> String {
        if let currencyInfo = currentCurrencyInfo {
            let symbol = currencyInfo.symbol
            let hasSpace = currencyInfo.spaceBetweenAmountAndSymbol
            let spacer = hasSpace ? " " : ""
            
            // Format number with thousands separator
            let formattedNumber = formatNumberWithSeparator(price, separator: currencyInfo.thousandsSeparator)
            
            if currencyInfo.symbolOnLeft {
                return "\(symbol)\(spacer)\(formattedNumber)"
            } else {
                return "\(formattedNumber)\(spacer)\(symbol)"
            }
        } else {
            // Fallback to selected currency or default
            if let currency = selectedCurrency {
                let symbol = currency.symbol ?? currency.code
                return "\(symbol)\(price)"
            } else {
                return "₹\(price)"
            }
        }
    }
    
    private func formatNumberWithSeparator(_ number: Int, separator: String) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = separator
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - Update Currency Info from API
    func updateCurrencyInfo(_ info: CurrencyDetail) {
        DispatchQueue.main.async {
            self.currentCurrencyInfo = info
        }
    }
    
    func updateCurrencyInfo(_ info: CurrencyInfo) {
        let currencyDetail = CurrencyDetail(
            code: info.code,
            symbol: info.symbol,
            thousandsSeparator: info.thousandsSeparator,
            decimalSeparator: info.decimalSeparator,
            symbolOnLeft: info.symbolOnLeft,
            spaceBetweenAmountAndSymbol: info.spaceBetweenAmountAndSymbol,
            decimalDigits: info.decimalDigits
        )
        updateCurrencyInfo(currencyDetail)
    }
    
    // MARK: - Persistence
    private func saveCurrency() {
        if let currency = selectedCurrency {
            if let data = try? JSONEncoder().encode(currency) {
                userDefaults.set(data, forKey: currencyKey)
            }
        } else {
            userDefaults.removeObject(forKey: currencyKey)
        }
    }
    
    private func saveCountry() {
        if let country = selectedCountry {
            if let data = try? JSONEncoder().encode(country) {
                userDefaults.set(data, forKey: countryKey)
            }
        } else {
            userDefaults.removeObject(forKey: countryKey)
        }
    }
    
    private func loadSavedSelections() {
        // Load currency
        if let data = userDefaults.data(forKey: currencyKey),
           let currency = try? JSONDecoder().decode(Currency.self, from: data) {
            selectedCurrency = currency
        } else {
            // Default to INR
            selectedCurrency = MockDataService.shared.findCurrency(byCode: "INR")
        }
        
        // Load country
        if let data = userDefaults.data(forKey: countryKey),
           let country = try? JSONDecoder().decode(Country.self, from: data) {
            selectedCountry = country
        } else {
            // Default to India
            selectedCountry = MockDataService.shared.findCountry(byCode: "IN")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let currencyChanged = Notification.Name("currencyChanged")
    static let countryChanged = Notification.Name("countryChanged")
}
