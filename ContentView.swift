import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            SetupView()
                .tabItem { Label("Allergens", systemImage: "checklist") }
        }
    }
}
