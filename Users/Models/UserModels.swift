
import Foundation

// MARK: - User Creation Models
struct UserCreationRequest: Codable {
    let device_id: String
    let device_id_type: String
    let app: String
    let vendor_id: String
    let pseudo_id: String
    let email: String?
    let acquired_route: String
    let referrer_url: String?
    
    init(
        device_id: String,
        device_id_type: String = "idfa",
        app: String = "d2_ios_flight",
        vendor_id: String,
        pseudo_id: String,
        email: String? = nil,
        acquired_route: String = "unknown",
        referrer_url: String? = nil
    ) {
        self.device_id = device_id
        self.device_id_type = device_id_type
        self.app = app
        self.vendor_id = vendor_id
        self.pseudo_id = pseudo_id
        self.email = email
        self.acquired_route = acquired_route
        self.referrer_url = referrer_url
    }
}

struct UserCreationResponse: Codable {
    let msg: String
    let user_id: Int
}

// MARK: - Session Creation Models
struct SessionCreationRequest: Codable {
    let user_id: Int
    let type: String
    let tag: String?
    let route: String
    let vertical: String
    let country_code: String
    let ad_id: String?
    let adgroup_id: String?
    let campaign_id: String?
    let campaign_group_id: String?
    let account_id: String?
    let ad_objective_name: String?
    let gclid: String?
    let fbclid: String?
    let msclkid: String?
    
    init(
        user_id: Int,
        type: String = "api",
        tag: String? = nil,
        route: String = "organic",
        vertical: String = "flight",
        country_code: String = "IN",
        ad_id: String? = nil,
        adgroup_id: String? = nil,
        campaign_id: String? = nil,
        campaign_group_id: String? = nil,
        account_id: String? = nil,
        ad_objective_name: String? = nil,
        gclid: String? = nil,
        fbclid: String? = nil,
        msclkid: String? = nil
    ) {
        self.user_id = user_id
        self.type = type
        self.tag = tag
        self.route = route
        self.vertical = vertical
        self.country_code = country_code
        self.ad_id = ad_id
        self.adgroup_id = adgroup_id
        self.campaign_id = campaign_id
        self.campaign_group_id = campaign_group_id
        self.account_id = account_id
        self.ad_objective_name = ad_objective_name
        self.gclid = gclid
        self.fbclid = fbclid
        self.msclkid = msclkid
    }
}

struct SessionCreationResponse: Codable {
    let msg: String
    let user_id: Int
    let user_session_id: Int
}

// MARK: - User Session Event Types
enum UserEventType: String, CaseIterable {
    case searchButtonClick = "search_button_click"
    case adClick = "ad_click"
    case appLaunch = "app_launch"
    case flightSearch = "flight_search"
    case hotelSearch = "hotel_search"
    case rentalSearch = "rental_search"
    case filterApplied = "filter_applied"
    case resultSelected = "result_selected"
    case bookingAttempt = "booking_attempt"
    case locationSelected = "location_selected"
    case dateSelected = "date_selected"
}

// MARK: - User Vertical Types
enum UserVertical: String, CaseIterable {
    case flight = "flight"
    case hotel = "hotel"
    case car = "car"
    case general = "general"
}
