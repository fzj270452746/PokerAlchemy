import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PAGameView()
                .tabItem { PATabLabel(icon: "flame.fill", title: "Forge") }
                .tag(0)

            PARecipeBookView()
                .tabItem { PATabLabel(icon: "book.closed.fill", title: "Codex") }
                .tag(1)

            PAForgeView()
                .tabItem { PATabLabel(icon: "hammer.fill", title: "Workshop") }
                .tag(2)

            PAEndlessView()
                .tabItem { PATabLabel(icon: "infinity", title: "Endless") }
                .tag(3)

            PAArchiveView()
                .tabItem { PATabLabel(icon: "scroll.fill", title: "Archive") }
                .tag(4)

            PASettingsView()
                .tabItem { PATabLabel(icon: "gearshape.fill", title: "Settings") }
                .tag(5)
        }
        .preferredColorScheme(.dark)
    }
}
