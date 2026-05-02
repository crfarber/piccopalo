import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProteinViewModel())
        .environmentObject(AccountViewModel())
}
