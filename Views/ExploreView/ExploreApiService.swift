import Alamofire
import Foundation
import Combine

// MARK: - API Service
class ExploreAPIService {
    static let shared = ExploreAPIService()
    
    private(set) var lastFetchedCurrencyInfo: CurrencyDetail?
    
    // At the top of ExploreAPIService
    weak var viewModelReference: ExploreViewModel?
    
    var currency: String {
        return CurrencyManager.shared.currencyCode
    }

    var country: String {
        return CurrencyManager.shared.countryCode
    }
    
    private let baseURL = "https://staging.plane.lascade.com/api/explore/"
    private var flightsURL: String {
        return "https://staging.plane.lascade.com/api/explore/?currency=\(currency)&country=\(country)"
    }
    private var currentFlightSearchRequest: DataRequest?
    private let session = Session()
    
    // FIXED: Corrected pollFlightResultsPaginated method
    func pollFlightResultsPaginated(searchId: String, page: Int = 1, limit: Int = 30, filterRequest: FlightFilterRequest? = nil) -> AnyPublisher<FlightPollResponse, Error> {
        let baseURL = "https://staging.plane.lascade.com/api/poll/"
        
        // Build query parameters
        let parameters: [String: String] = [
            "search_id": searchId,
            "page": String(page),
            "limit": String(limit)
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        // Create request
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(country, forHTTPHeaderField: "country")
        
        // CRITICAL FIX: Build request body correctly
        var requestDict: [String: Any] = [:]
        
        // FIXED: Only add filters if filterRequest is provided AND has meaningful values
        if let filterRequest = filterRequest {
            print("🔧 Building filter request body:")
            
            // Only add fields that have meaningful values
            if let durationMax = filterRequest.durationMax, durationMax > 0 {
                requestDict["duration_max"] = durationMax
                print("   Duration max: \(durationMax) minutes")
            }
            
            if let stopCountMax = filterRequest.stopCountMax {
                requestDict["stop_count_max"] = stopCountMax
                print("   Stop count max: \(stopCountMax)")
            }
            
            if let ranges = filterRequest.arrivalDepartureRanges, !ranges.isEmpty {
                var rangesArray: [[String: Any]] = []
                
                for range in ranges {
                    var rangeDict: [String: Any] = [:]
                    
                    if let arrival = range.arrival {
                        var arrivalDict: [String: Any] = [:]
                        if let min = arrival.min {
                            arrivalDict["min"] = min
                        }
                        if let max = arrival.max {
                            arrivalDict["max"] = max
                        }
                        if !arrivalDict.isEmpty {
                            rangeDict["arrival"] = arrivalDict
                        }
                    }
                    
                    if let departure = range.departure {
                        var departureDict: [String: Any] = [:]
                        if let min = departure.min {
                            departureDict["min"] = min
                        }
                        if let max = departure.max {
                            departureDict["max"] = max
                        }
                        if !departureDict.isEmpty {
                            rangeDict["departure"] = departureDict
                        }
                    }
                    
                    if !rangeDict.isEmpty {
                        rangesArray.append(rangeDict)
                    }
                }
                
                if !rangesArray.isEmpty {
                    requestDict["arrival_departure_ranges"] = rangesArray
                    print("   Time ranges: \(rangesArray.count) ranges")
                }
            }
            
            // Only add non-empty arrays
            if let exclude = filterRequest.iataCodesExclude, !exclude.isEmpty {
                requestDict["iata_codes_exclude"] = exclude
                print("   Exclude airlines: \(exclude)")
            }
            
            if let include = filterRequest.iataCodesInclude, !include.isEmpty {
                requestDict["iata_codes_include"] = include
                print("   Include airlines: \(include)")
            }
            
            // Only add sorting if it's specified AND it's a valid value
            if let sortBy = filterRequest.sortBy, !sortBy.isEmpty {
                // Only use valid sort values
                let validSortValues = ["price", "duration", "departure", "arrival"]
                if validSortValues.contains(sortBy) {
                    requestDict["sort_by"] = sortBy
                    print("   Sort by: \(sortBy)")
                    
                    // Add sort_order if needed
                    if let sortOrder = filterRequest.sortOrder, !sortOrder.isEmpty {
                        requestDict["sort_order"] = sortOrder
                        print("   Sort order: \(sortOrder)")
                    } else {
                        // Default sort order is ascending
                        requestDict["sort_order"] = "asc"
                        print("   Sort order: asc (default)")
                    }
                } else {
                    print("   ⚠️ Invalid sort value ignored: \(sortBy)")
                }
            }
            
            // Only add non-empty arrays
            if let agencyExclude = filterRequest.agencyExclude, !agencyExclude.isEmpty {
                requestDict["agency_exclude"] = agencyExclude
                print("   Exclude agencies: \(agencyExclude)")
            }
            
            if let agencyInclude = filterRequest.agencyInclude, !agencyInclude.isEmpty {
                requestDict["agency_include"] = agencyInclude
                print("   Include agencies: \(agencyInclude)")
            }
            
            // Only add price constraints if they're meaningful
            if let priceMin = filterRequest.priceMin, priceMin > 0 {
                requestDict["price_min"] = priceMin
                print("   Price min: ₹\(priceMin)")
            }
            
            if let priceMax = filterRequest.priceMax, priceMax > 0 {
                requestDict["price_max"] = priceMax
                print("   Price max: ₹\(priceMax)")
            }
        }
        
        // CRITICAL FIX: Add body to request - ALWAYS use the requestDict (empty {} if no filters)
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestDict)
            
            if requestDict.isEmpty {
                print("🔧 Empty filter request body (no filters applied) - will get ALL results")
            } else if let requestBody = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                print("🔧 Final API request body: \(requestBody)")
            }
        } catch {
            print("❌ Error encoding filter request: \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🚀 Making API call to poll endpoint")
        print("   Search ID: \(searchId)")
        print("   Page: \(page)")
        print("   Limit: \(limit)")
        
        // Return a publisher that will emit results
        return Future<FlightPollResponse, Error> { promise in
            AF.request(request)
                .validate()
                .responseData { [weak self] response in
                    // Log response details
                    print("📡 Poll API Response:")
                    print("   Status Code: \(response.response?.statusCode ?? 0)")
                    
                    switch response.result {
                    case .success(let data):
                        do {
                            let pollResponse = try JSONDecoder().decode(FlightPollResponse.self, from: data)
                            
                            // Store response in viewModel
                            self?.viewModelReference?.lastPollResponse = pollResponse
                            
                            // Update the total count
                            self?.viewModelReference?.totalFlightCount = pollResponse.count
                            
                            // Update cache status
                            self?.viewModelReference?.isDataCached = pollResponse.cache
                            
                            print("✅ Poll response decoded successfully:")
                            print("   Results: \(pollResponse.results.count)")
                            print("   Total: \(pollResponse.count)")
                            print("   Cached: \(pollResponse.cache)")
                            print("   Has Next: \(pollResponse.next != nil)")
                            
                            promise(.success(pollResponse))
                        } catch {
                            print("❌ Poll response decoding error: \(error)")
                            if let responseStr = String(data: data, encoding: .utf8) {
                                print("   Response data: \(responseStr.prefix(500))")
                            }
                            promise(.failure(error))
                        }
                    case .failure(let error):
                        print("❌ Poll API request failed: \(error)")
                        if let data = response.data, let responseStr = String(data: data, encoding: .utf8) {
                            print("   Error response: \(responseStr.prefix(500))")
                        }
                        promise(.failure(error))
                    }
                }
        }.eraseToAnyPublisher()
    }
    
    func searchFlights(origin: String, destination: String, returndate: String, departuredate: String,
                      roundTrip: Bool = true, adults: Int = 1, childrenAges: [Int?] = [], cabinClass: String = "economy") -> AnyPublisher<SearchResponse, Error> {
        let baseURL = "https://staging.plane.lascade.com/api/search/"
        
        let parameters: [String: String] = [
            "user_id": "-0",
            "currency": currency,
            "language": "en-GB",
            "app_code": "D1WF"
        ]
        
        // Create legs based on round trip status
        var legs: [[String: String]] = [
            [
                "origin": origin,
                "destination": destination,
                "date": departuredate
            ]
        ]
        
        // Only add return leg if it's a round trip
        if roundTrip && !returndate.isEmpty {
            legs.append([
                "origin": destination,
                "destination": origin,
                "date": returndate
            ])
        }
        
        // Filter out nil values from childrenAges and convert to Int array
        let validChildrenAges = childrenAges.compactMap { $0 }
        
        let requestData: [String: Any] = [
            "legs": legs,
            "cabin_class": cabinClass.lowercased(),
            "adults": adults,
            "children_ages": validChildrenAges
        ]
        
        // Create URL with query parameters
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(country, forHTTPHeaderField: "country")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)
        
        return Future<SearchResponse, Error> { promise in
            AF.request(request)
                .validate()
                .responseDecodable(of: SearchResponse.self) { response in
                    switch response.result {
                    case .success(let searchResponse):
                        // UPDATED: Update currency info in CurrencyManager
                        CurrencyManager.shared.updateCurrencyInfo(searchResponse.currencyInfo)
                        promise(.success(searchResponse))
                    case .failure(let error):
                        print("Search API error: \(error.localizedDescription)")
                        if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                            print("Response body: \(responseString)")
                        }
                        promise(.failure(error))
                    }
                }
        }.eraseToAnyPublisher()
    }
    
    func fetchAutocomplete(query: String, country: String? = nil, language: String = "en-GB") -> AnyPublisher<[AutocompleteResult], Error> {
        let baseURL = "https://staging.plane.lascade.com/api/autocomplete"
        
        let finalCountry = country ?? self.country

        let parameters: [String: String] = [
            "search": query,
            "country": finalCountry,
            "language": language
        ]
        
        return Future<[AutocompleteResult], Error> { promise in
            AF.request(baseURL, parameters: parameters)
                .validate()
                .responseDecodable(of: AutocompleteResponse.self) { response in
                    switch response.result {
                    case .success(let autocompleteResponse):
                        promise(.success(autocompleteResponse.data))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
        }.eraseToAnyPublisher()
    }
    
    func fetchDestinations(country: String? = nil,
                          currency: String? = nil,
                              departure: String = "COK",
                              language: String = "en-GB",
                              arrivalType: String = "country",
                              arrivalId: String? = nil) -> AnyPublisher<[ExploreDestination], Error> {
            
            // Create URL components for the updated API endpoint
            var urlComponents = URLComponents(string: self.baseURL)!
            
            // Add query parameters
        let finalCountry = country ?? self.country
        let finalCurrency = currency ?? self.currency

        // Add query parameters
        var queryItems = [
            URLQueryItem(name: "country", value: finalCountry),
            URLQueryItem(name: "currency", value: finalCurrency),
                URLQueryItem(name: "departure", value: departure),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "arrival_type", value: arrivalType)
            ]
            
            // Add optional arrivalId if provided
            if let arrivalId = arrivalId {
                queryItems.append(URLQueryItem(name: "arrival_id", value: arrivalId))
            }
            
            urlComponents.queryItems = queryItems
            
            // Create the URL request
            let request = URLRequest(url: urlComponents.url!)
            
            return Future<[ExploreDestination], Error> { promise in
                AF.request(request)
                    .validate()
                    .responseDecodable(of: ExploreApiResponse.self) { response in
                        switch response.result {
                        case .success(let apiResponse):
                            // UPDATED: Update currency info in CurrencyManager
                            CurrencyManager.shared.updateCurrencyInfo(apiResponse.currency)
                            self.lastFetchedCurrencyInfo = apiResponse.currency
                            // Convert the new API response to the existing ExploreDestination model
                            let destinations = apiResponse.data.map { item -> ExploreDestination in
                                return ExploreDestination(
                                    price: item.price,
                                    location: ExploreLocation(
                                        entityId: item.location.entityId,
                                        name: item.location.name,
                                        iata: item.location.iata
                                    ),
                                    is_direct: item.is_direct
                                )
                            }
                            promise(.success(destinations))
                            
                        case .failure(let error):
                            print("API error: \(error.localizedDescription)")
                            if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                                print("Response body: \(responseString)")
                            }
                            promise(.failure(error))
                        }
                    }
            }.eraseToAnyPublisher()
        }
    
    // Add a helper method to get the currency symbol from API response
    func getCurrencySymbol(from apiResponse: ExploreApiResponse) -> String {
        return apiResponse.currency.symbol
    }
    
    // In ExploreAPIService, update the fetchFlightDetails method
    func fetchFlightDetails(
        origin: String = "COK", // Default to COK
        destination: String,
        departure: String,
        roundTrip: Bool = true,
    ) -> AnyPublisher<FlightSearchResponse, Error> {
        
        // Use COK as default origin if empty
        let finalOrigin = origin.isEmpty ? "COK" : origin
        
        print("origin: \(finalOrigin)")
        print("dest: \(destination)")
        print("dep: \(departure)")
        print("roundTrip: \(roundTrip)")
        print("currency: \(currency)")
        print("country: \(country)")
        
        // Create request parameters according to requirements
        let parameters: [String: Any] = [
            "origin": finalOrigin,
            "destination": destination,
            "departure": departure,
            "round_trip": roundTrip,
        ]
        
        return Future<FlightSearchResponse, Error> { promise in
            AF.request(self.flightsURL,
                      method: .post,
                      parameters: parameters,
                      encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: FlightSearchResponse.self) { response in
                    switch response.result {
                    case .success(let searchResponse):
                        promise(.success(searchResponse))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
        }.eraseToAnyPublisher()
    }
}
