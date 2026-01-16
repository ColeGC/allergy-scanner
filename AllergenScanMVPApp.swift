import SwiftUI

@main
struct AllergenScanMVPApp: App {
    @StateObject private var store = UserAllergenStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
