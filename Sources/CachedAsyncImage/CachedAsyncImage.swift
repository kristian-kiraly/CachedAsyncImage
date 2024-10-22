// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  CachedAsyncImage.swift
//
//  Created by Kristian Kiraly on 8/26/24.
//

import SwiftUI

enum CachedAsyncImageError: LocalizedError {
    case emptyResponse
    case invalidData
    case invalidResponse
    case invalidResponseCode(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Empty response"
        case .invalidData:
            return "Invalid data"
        case .invalidResponse:
            return "Invalid response"
        case .invalidResponseCode(let code):
            return "Invalid response code: \(code)"
        }
    }
}

public struct CachedAsyncImage<ProgressPlaceholder: View, ErrorPlaceholder: View>: View {
    let url: URL
    @ViewBuilder let progressView: () -> ProgressPlaceholder
    @ViewBuilder let errorView: (Error) -> ErrorPlaceholder
    
    @State private var image: UIImage? = nil
    @State private var error: Error?

    private let cache = URLCache.shared
    
    public init(url: URL, @ViewBuilder progressView: @escaping () -> ProgressPlaceholder = { ProgressView() }, @ViewBuilder errorView: @escaping (Error) -> ErrorPlaceholder = { error in
        Text(error.localizedDescription)
    }) {
        self.url = url
        self.progressView = progressView
        self.errorView = errorView
    }

    public var body: some View {
        if let image = image ?? cachedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            if let error {
                errorView(error)
            } else {
                Color.clear
                    .overlay {
                        progressView()
                    }
                    .task {
                        await loadImage()
                    }
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
            guard let httpResponse = response as? HTTPURLResponse
            else {
                await MainActor.run {
                    error = CachedAsyncImageError.invalidResponse
                }
                return
            }
            guard httpResponse.statusCode == 200
            else {
                await MainActor.run {
                    error = CachedAsyncImageError.invalidResponseCode("\(httpResponse.statusCode)")
                }
                return
            }
               
            guard let fetchedImage = UIImage(data: data)
            else {
                await MainActor.run {
                    error = CachedAsyncImageError.invalidData
                }
                return
            }
            self.image = fetchedImage
            let cachedData = CachedURLResponse(response: response, data: data)
            cache.storeCachedResponse(cachedData, for: Self.request(url: url))
        } catch {
            // Handle error
            print("Error loading image: \(error)")
            await MainActor.run {
                self.error = error
            }
        }
    }
}

#Preview("Standard") {
    CachedAsyncImage(url: URL(string: "https://picsum.photos/200/300")!)
}

#Preview("Custom Progress") {
    CachedAsyncImage(url: URL(string: "https://picsum.photos/200/300")!) {
        Text("Loading...")
    }
}

#Preview("Error State") {
    CachedAsyncImage(url: URL(string: "https://picsum.photos/200/300.")!)
}

#Preview("Custom Error State") {
    CachedAsyncImage(url: URL(string: "https://picsum.photos/200/300.")!, errorView: { error in
        Text("Error! \(error.localizedDescription)")
    })
}
