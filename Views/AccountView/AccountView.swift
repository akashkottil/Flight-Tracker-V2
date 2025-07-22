import SwiftUI
import Combine

// MARK: - ViewModels
class CountryViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var searchText = ""
    @Published var selectedCountry: Country?
    
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load all countries initially
        countries = dataService.getAllCountries()
        
        // Setup search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchQuery in
                self?.searchCountries(query: searchQuery)
            }
            .store(in: &cancellables)
    }
    
    private func searchCountries(query: String) {
        countries = dataService.searchCountries(query: query)
    }
}

class CurrencyViewModel: ObservableObject {
    @Published var currencies: [Currency] = []
    @Published var searchText = ""
    @Published var selectedCurrency: Currency?
    
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load all currencies initially
        currencies = dataService.getAllCurrencies()
        
        // Setup search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchQuery in
                self?.searchCurrencies(query: searchQuery)
            }
            .store(in: &cancellables)
    }
    
    private func searchCurrencies(query: String) {
        currencies = dataService.searchCurrencies(query: query)
    }
}

// MARK: - Currency Selection Sheet
struct CurrencySelectionSheet: View {
    @StateObject private var viewModel = CurrencyViewModel()
    @Environment(\.dismiss) private var dismiss
    // UPDATED: Use CurrencyManager instead of local binding
    @ObservedObject var currencyManager = CurrencyManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Currency")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // Invisible button for spacing
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                Divider()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Search Currency", text: $viewModel.searchText)
                                .font(.system(size: 16))
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 15)
                    
                    // Currency List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.currencies) { currency in
                                CurrencyRow(
                                    currency: currency,
                                    // UPDATED: Use CurrencyManager selection
                                    isSelected: currencyManager.selectedCurrency?.code == currency.code
                                ) {
                                    // UPDATED: Update CurrencyManager
                                    currencyManager.selectedCurrency = currency
                                    dismiss()
                                }
                                
                                if currency != viewModel.currencies.last {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Flag or placeholder
                if let flag = currency.flag {
                    Text(flag)
                        .font(.system(size: 24))
                        .frame(width: 32, height: 24)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(width: 32, height: 24)
                        .overlay(
                            Text(currency.code.prefix(2))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(currency.code)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        if let symbol = currency.symbol {
                            Text("(\(symbol))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(currency.name)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Region Selection Sheet
struct RegionSelectionSheet: View {
    @StateObject private var viewModel = CountryViewModel()
    @Environment(\.dismiss) private var dismiss
    // UPDATED: Use CurrencyManager instead of local binding
    @ObservedObject var currencyManager = CurrencyManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Region")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // Invisible button for spacing
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                Divider()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Search Region", text: $viewModel.searchText)
                                .font(.system(size: 16))
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 15)
                    
                    // Country List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.countries) { country in
                                CountryRow(
                                    country: country,
                                    // UPDATED: Use CurrencyManager selection
                                    isSelected: currencyManager.selectedCountry?.code == country.code
                                ) {
                                    // UPDATED: Update CurrencyManager
                                    currencyManager.selectedCountry = country
                                    dismiss()
                                }
                                
                                if country != viewModel.countries.last {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Flag or placeholder
                if let flag = country.flag {
                    Text(flag)
                        .font(.system(size: 24))
                        .frame(width: 32, height: 24)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(width: 32, height: 24)
                        .overlay(
                            Text(country.code.prefix(2))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                
                Text(country.name)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Updated AccountView with Native Navigation
struct AccountView: View {
    @State private var showingCurrencySheet = false
    @State private var showingRegionSheet = false
    
    // UPDATED: Use CurrencyManager instead of local state
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    // ADD: Observe shared search data for navigation state
    @StateObject private var sharedSearchData = SharedSearchDataStore.shared
    
    // Legal items data for reusability
    private let legalItems = [
        "Request a feature",
        "Contact us",
        "Privacy Policy",
        "About us",
        "Rate our app"
    ]
    
    var body: some View {
        ScrollView {
            VStack {
 
                
                VStack(alignment: .leading, spacing: 15) {
                    // Login section
                    VStack(alignment: .leading) {
                        Text("Ready for Takeoff? ")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                        Text("Log In Now")
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                    }
                    
                    Text("Access your profile, manage settings, and view personalized features.")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                    Button(action: {}) {
                        Text("Login")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color("login"))
                            .cornerRadius(10)
                    }
                    
                    // App Settings section
                    SectionTitle(text: "App Settings")
                        .padding(.top,20)
                    
                    SettingCard(
                        title: "Region",
                        subtitle: currencyManager.selectedCountry?.name ?? "India",
                        icon: currencyManager.selectedCountry?.flag.map { Text($0) } ?? Text("🇮🇳"),
                        action: {
                            showingRegionSheet = true
                        }
                    )
                    
                    SettingCard(
                        title: "Currency",
                        subtitle: currencyManager.selectedCurrency?.name ?? "Indian Rupee",
                        icon: currencyManager.selectedCurrency?.flag.map { Text($0) } ?? Text("🇮🇳"),
                        action: {
                            showingCurrencySheet = true
                        }
                    )
                    
                    SettingCard(
                        title: "Display",
                        subtitle: "Light mode",
                        action: {}
                    )
                    
                    // Legal and Info section
                    SectionTitle(text: "Legal and Info")
                        .padding(.top,30)
                    
                    VStack(spacing: 10) {
                        ForEach(legalItems, id: \.self) { item in
                            LegalInfoItem(title: item, action: {})
                            
                            if item != legalItems.last {
                                Divider()
                                    .foregroundColor(Color("border").opacity(0.2))
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("border").opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Account")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .onAppear {
            // Customize the back button appearance while keeping native behavior
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.setBackIndicatorImage(
                UIImage(systemName: "chevron.left")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
                    .withTintColor(.black, renderingMode: .alwaysOriginal),
                transitionMaskImage: UIImage(systemName: "chevron.left")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            )
            appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(isPresented: $showingCurrencySheet) {
            CurrencySelectionSheet()
        }
        .sheet(isPresented: $showingRegionSheet) {
            RegionSelectionSheet()
        }
        .onAppear {
            // Set navigation state to hide tab bar
            sharedSearchData.enterAccountNavigation()
        }
        .onDisappear {
            // Reset navigation state to show tab bar
            sharedSearchData.exitAccountNavigation()
        }
    }
}

// MARK: - Reusable Components
struct SectionTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 18))
            .fontWeight(.bold)
            .padding(.vertical, 5)
    }
}

struct SettingCard: View {
    let title: String
    let subtitle: String
    var icon: Text? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading,spacing: 2) {
                    Spacer()
                    Text(title)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                    
                    HStack {
                        icon?
                            .font(.system(size: 16))
                        Text(subtitle)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.black)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("border").opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LegalInfoItem: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                    Spacer()
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.black)
                    .fontWeight(.bold)
            }
            .padding(.vertical,5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    AccountView()
}
