import Foundation
import Combine

class AutocompleteViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [AutocompleteItem] = []
    @Published var isLoading = false
    @Published var error: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard !text.isEmpty else {
                    self?.results = []
                    return
                }
                self?.fetchSuggestions(for: text)
            }
            .store(in: &cancellables)
    }

    func fetchSuggestions(for query: String) {
        let baseURL = "https://staging.plane.lascade.com/api/autocomplete"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "country", value: "IN"),
            URLQueryItem(name: "language", value: "en-GB")
        ]

        guard let url = components.url else {
            print("Invalid URL")
            return
        }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Network error:", error)
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
//                    self?.results = decoded.data
                    //TODO: check it pls ?
                } catch {
                    self?.error = error.localizedDescription
                    print("Decoding error:", error)
                }
            }
        }.resume()
    }
}
