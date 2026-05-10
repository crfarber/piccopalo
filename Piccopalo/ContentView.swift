import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isAuthenticated {
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
        } else {
            LoginView()
        }
    }
}

#Preview {
    let (container, protein, account) = PersistenceController.previewStack()
    ContentView()
        .environmentObject(protein)
        .environmentObject(account)
        .environmentObject(AuthViewModel())
        .modelContainer(container)
}
