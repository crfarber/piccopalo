import SwiftData
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
    let (container, protein, account) = PersistenceController.previewStack()
    ContentView()
        .environmentObject(protein)
        .environmentObject(account)
        .modelContainer(container)
}
