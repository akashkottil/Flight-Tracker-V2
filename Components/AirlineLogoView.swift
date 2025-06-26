//
//  AirlineLogoView.swift
//  AllFlights
//
//  Enhanced version to work with current data structure
//

import SwiftUI

struct AirlineLogoView: View {
    let iataCode: String?
    let fallbackImage: String
    let size: CGFloat
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    init(iataCode: String?, fallbackImage: String = "FlightTrackLogo", size: CGFloat = 34) {
        self.iataCode = iataCode
        self.fallbackImage = fallbackImage
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(width: size/2, height: size/2)
            } else {
                Image(fallbackImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(6)
        .onAppear {
            loadImageOptimized()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryPressure)) { _ in
            if loadedImage != nil {
                loadedImage = nil
            }
        }
    }
    
    // ✅ ENHANCED: Better IATA code processing
    private func processIataCode() -> String? {
        guard let rawCode = iataCode else {
            print("⚠️ AirlineLogoView: No IATA code provided")
            return nil
        }
        
        let cleaned = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        print("🔍 AirlineLogoView: Processing IATA code: '\(rawCode)' -> '\(cleaned)'")
        
        // Handle different input formats
        if cleaned.isEmpty {
            print("⚠️ AirlineLogoView: Empty IATA code after cleaning")
            return nil
        }
        
        // If it's already a clean 2-3 character code
        if cleaned.count <= 3 && cleaned.allSatisfy({ $0.isLetter || $0.isNumber }) {
            print("✅ AirlineLogoView: Using clean IATA code: '\(cleaned)'")
            return cleaned
        }
        
        // Try to extract from flight number format (e.g., "6E 703")
        if cleaned.contains(" ") {
            let components = cleaned.components(separatedBy: " ")
            if let firstComponent = components.first,
               firstComponent.count >= 2 && firstComponent.count <= 3 {
                print("✅ AirlineLogoView: Extracted from flight number: '\(firstComponent)'")
                return firstComponent
            }
        }
        
        // Extract first 2-3 characters if it looks like a flight number
        if cleaned.count >= 2 {
            let prefix = String(cleaned.prefix(2))
            if prefix.contains(where: { $0.isLetter }) {
                print("✅ AirlineLogoView: Extracted prefix: '\(prefix)'")
                return prefix
            }
        }
        
        print("❌ AirlineLogoView: Could not process IATA code from: '\(rawCode)'")
        return nil
    }
    
    // ✅ ENHANCED: Multiple loading strategies
    private func loadAirlineImage(iataCode: String) -> UIImage? {
        print("🔍 AirlineLogoView: Attempting to load image for: '\(iataCode)'")
        
        // Strategy 1: Load from Resource folder with directory path
        if let path = Bundle.main.path(forResource: iataCode, ofType: "png", inDirectory: "Resource/airlinesicons"),
           let uiImage = UIImage(contentsOfFile: path) {
            print("✅ Loaded '\(iataCode).png' from Resource/airlinesicons folder")
            return uiImage
        }
        
        // Strategy 2: Load directly from main bundle
        if let uiImage = UIImage(named: iataCode) {
            print("✅ Loaded '\(iataCode).png' from main bundle")
            return uiImage
        }
        
        // Strategy 3: Load with full path
        if let uiImage = UIImage(named: "Resource/airlinesicons/\(iataCode)") {
            print("✅ Loaded '\(iataCode).png' with full Resource path")
            return uiImage
        }
        
        // Strategy 4: Try different file extensions
        for ext in ["png", "PNG", "jpg", "jpeg"] {
            if let path = Bundle.main.path(forResource: iataCode, ofType: ext, inDirectory: "Resource/airlinesicons"),
               let uiImage = UIImage(contentsOfFile: path) {
                print("✅ Loaded '\(iataCode).\(ext)' from Resource folder")
                return uiImage
            }
        }
        
        // Debug: List available files
        debugAvailableFiles()
        
        print("❌ Failed to load any image for IATA code: '\(iataCode)'")
        return nil
    }
    
    // ✅ ENHANCED: Fallback view with debug info
    private func fallbackImageView(attemptedCode: String?) -> some View {
        ZStack {
            Image(fallbackImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            // Optional: Show attempted code as overlay for debugging
            if let code = attemptedCode {
                VStack {
                    Spacer()
                    Text(code)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(2)
                }
            }
        }
    }
    
    // ✅ DEBUG: List available files in the bundle
    private func debugAvailableFiles() {
        guard let resourcePath = Bundle.main.resourcePath else {
            print("❌ No resource path found in bundle")
            return
        }
        
        let airlineIconsPath = "\(resourcePath)/Resource/airlinesicons"
        
        if FileManager.default.fileExists(atPath: airlineIconsPath) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: airlineIconsPath)
                let imageFiles = files.filter { $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".jpg") }
                print("📁 Available airline icons: \(imageFiles)")
                
                // Show first few IATA codes we have images for
                let iataCodes = imageFiles.compactMap { fileName -> String? in
                    let nameWithoutExt = (fileName as NSString).deletingPathExtension
                    return nameWithoutExt.count <= 3 ? nameWithoutExt : nil
                }
                print("🏷️ Available IATA codes: \(Array(iataCodes.prefix(10)))")
                
            } catch {
                print("❌ Error reading airline icons directory: \(error)")
            }
        } else {
            print("❌ Airline icons directory not found at: \(airlineIconsPath)")
            
            // Try to find where Resource folder might be
            do {
                let allFiles = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let resourceFolders = allFiles.filter { $0.lowercased().contains("resource") }
                print("📁 Found resource-related folders: \(resourceFolders)")
            } catch {
                print("❌ Error reading bundle contents: \(error)")
            }
        }
    }
    
    private func loadImageOptimized() {
        guard let processedCode = processIataCode(),
              loadedImage == nil else { return }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: processedCode) {
            loadedImage = cachedImage
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = loadAirlineImageSync(iataCode: processedCode) {
                let optimizedImage = optimizeImageForDisplay(image, targetSize: CGSize(width: size * 2, height: size * 2))
                ImageCache.shared.setImage(optimizedImage, forKey: processedCode)
                
                DispatchQueue.main.async {
                    self.loadedImage = optimizedImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    private func loadAirlineImageSync(iataCode: String) -> UIImage? {
        print("🔍 AirlineLogoView: Attempting to load image for: '\(iataCode)'")
        
        // Strategy 1: Load from Resource folder with directory path
        if let path = Bundle.main.path(forResource: iataCode, ofType: "png", inDirectory: "Resource/airlinesicons"),
           let uiImage = UIImage(contentsOfFile: path) {
            print("✅ Loaded '\(iataCode).png' from Resource/airlinesicons folder")
            return uiImage
        }
        
        // Strategy 2: Load directly from main bundle
        if let uiImage = UIImage(named: iataCode) {
            print("✅ Loaded '\(iataCode).png' from main bundle")
            return uiImage
        }
        
        // Strategy 3: Try different file extensions
        for ext in ["png", "PNG", "jpg", "jpeg"] {
            if let path = Bundle.main.path(forResource: iataCode, ofType: ext, inDirectory: "Resource/airlinesicons"),
               let uiImage = UIImage(contentsOfFile: path) {
                print("✅ Loaded '\(iataCode).\(ext)' from Resource folder")
                return uiImage
            }
        }
        
        print("❌ Failed to load any image for IATA code: '\(iataCode)'")
        return nil
    }

    private func optimizeImageForDisplay(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
}

// ✅ ENHANCED: Better extension for flight number parsing
extension String {
    var airlineIataCode: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Extracting IATA code from: '\(trimmed)'")
        
        // Handle space-separated format (e.g., "6E 703")
        if trimmed.contains(" ") {
            let components = trimmed.components(separatedBy: " ")
            if let firstComponent = components.first,
               firstComponent.count >= 2 && firstComponent.count <= 3,
               firstComponent.contains(where: { $0.isLetter }) {
                print("✅ Extracted from space-separated: '\(firstComponent)'")
                return firstComponent.uppercased()
            }
        }
        
        // Handle no-space format (e.g., "6E703") - ALWAYS take first 2 characters
        if trimmed.count >= 2 {
            let airlineCode = String(trimmed.prefix(2))
            // Validate that it contains at least one letter
            if airlineCode.contains(where: { $0.isLetter }) {
                print("✅ Extracted first 2 chars: '\(airlineCode)'")
                return airlineCode.uppercased()
            }
        }
        
        print("❌ Could not extract IATA code from: '\(trimmed)'")
        return nil
    }
}

// ✅ COMMON IATA CODES: For testing purposes
extension AirlineLogoView {
    static let commonIndianAirlines = [
        "6E": "IndiGo",
        "AI": "Air India",
        "SG": "SpiceJet",
        "UK": "Vistara",
        "G8": "GoFirst",
        "IX": "Air India Express",
        "9W": "Jet Airways",
        "I5": "AirAsia India"
    ]
    
    static func testIataCodeExtraction() {
        let testFlightNumbers = [
            "6E 703", "6E703", "AI 131", "AI131",
            "SG 8009", "UK 955", "G8 101", "IX 493"
        ]
        
        print("🧪 TESTING IATA CODE EXTRACTION:")
        for flightNumber in testFlightNumbers {
            let extracted = flightNumber.airlineIataCode
            print("  '\(flightNumber)' -> '\(extracted ?? "nil")'")
        }
    }
}
