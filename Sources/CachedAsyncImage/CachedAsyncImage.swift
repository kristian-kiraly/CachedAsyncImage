// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  CachedAsyncImage.swift
//
//  Created by Kristian Kiraly on 8/26/24.
//

import SwiftUI

public struct CachedAsyncImage: View {
    let url: URL
    
    @State private var image: UIImage? = nil

    private let cache = URLCache.shared
    
    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        if let image = image ?? cachedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color.clear
                .overlay {
                    ProgressView()
                }
                .task {
                    await loadImage()
                }
        }
    }
    
    public static func cachedImage(url: URL) -> UIImage? {
        guard let cachedResponse = URLCache.shared.cachedResponse(for: request(url: url)),
           let cachedImage = UIImage(data: cachedResponse.data)
        else { return nil }
        return cachedImage
    }
    
    private static func request(url: URL) -> URLRequest {
        URLRequest(url: url)
    }
    
    private var cachedImage: UIImage? {
        Self.cachedImage(url: url)
    }

    private func loadImage() async {
        do {
            let (data, response) = try await URLSession.shared.data(for: Self.request(url: url))
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let fetchedImage = UIImage(data: data) {
                self.image = fetchedImage
                let cachedData = CachedURLResponse(response: response, data: data)
                cache.storeCachedResponse(cachedData, for: Self.request(url: url))
            }
        } catch {
            // Handle error
            print("Error loading image: \(error)")
        }
    }
}
