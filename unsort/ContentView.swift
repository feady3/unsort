import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WriteMemoView()
                .tabItem {
                    Label("Write", systemImage: "pencil.circle.fill")
                }
            
            ClustersView()
                .tabItem {
                    Label("Reflect", systemImage: "square.grid.2x2.fill")
                }
        }
    }
}
