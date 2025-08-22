import SwiftUI

@main
struct VocaToApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .preferredColorScheme(nil) // Follow system; single design for light/dark
                .tint(Color("PrimaryGreen"))
        }
    }
}

