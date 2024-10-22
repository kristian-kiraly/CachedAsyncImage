# CachedAsyncImage

A simple SwiftUI cached image manager that allows you to pass a URL and get an image if it's available. It allows custom progress indicators and error states or it can be used by simply passing a URL alone. Cached images using the same URL will automatically load the cached image immediately when used anywhere else in the app.

Usage:

```swift
struct ContentView: View {
    let url: URL
    
    var body: some View {
        //Standard
        CachedAsyncImage(url: url)
        
        //Custom Progress
        CachedAsyncImage(url: url) {
            Text("Loading...")
        }
        
        //Custom Error
        CachedAsyncImage(url: url, errorView: { error in
            Text("Error! \(error.localizedDescription)")
        })
        
        //Both Custom
        CachedAsyncImage(url: url) {
            Text("Loading...")
        } errorView: { error in
            Text("Error! \(error.localizedDescription)")
        }
    }
}
```
