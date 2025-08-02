

import Foundation
import Alamofire

class UserApi {
    static let shared = UserApi()
    private init() {}
    
    private let baseURL = "https://staging.data.lascade.com/api/v1"
    
    // MARK: - Create User
    func createUser(
        request: UserCreationRequest,
        completion: @escaping (Result<UserCreationResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)/users/add/"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        print("👤 Creating user with request:")
        print("   Device ID: \(request.device_id)")
        print("   App: \(request.app)")
        print("   Vendor ID: \(request.vendor_id)")
        print("   Pseudo ID: \(request.pseudo_id)")
        
        AF.request(
            url,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: UserCreationResponse.self) { response in
            switch response.result {
            case .success(let userResponse):
                print("✅ User created successfully!")
                print("   User ID: \(userResponse.user_id)")
                print("   Message: \(userResponse.msg)")
                completion(.success(userResponse))
            case .failure(let error):
                print("❌ User creation failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Create Session
    func createSession(
        request: SessionCreationRequest,
        completion: @escaping (Result<SessionCreationResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)/users/session/"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        print("📊 Creating session for user \(request.user_id):")
        print("   Type: \(request.type)")
        print("   Vertical: \(request.vertical)")
        print("   Country: \(request.country_code)")
        print("   Route: \(request.route)")
        
        AF.request(
            url,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: SessionCreationResponse.self) { response in
            switch response.result {
            case .success(let sessionResponse):
                print("✅ Session created successfully!")
                print("   User ID: \(sessionResponse.user_id)")
                print("   Session ID: \(sessionResponse.user_session_id)")
                print("   Message: \(sessionResponse.msg)")
                completion(.success(sessionResponse))
            case .failure(let error):
                print("❌ Session creation failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
}
