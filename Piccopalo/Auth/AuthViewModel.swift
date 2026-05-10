import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var session: Session? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let auth = SupabaseManager.shared.client.auth

    var isAuthenticated: Bool { session != nil }

    init() {
        Task {
            await loadCurrentSession()
            observeAuthChanges()
        }
    }

    // MARK: - Session

    private func loadCurrentSession() async {
        session = try? await auth.session
    }

    private func observeAuthChanges() {
        Task {
            for await (_, session) in auth.authStateChanges {
                self.session = session
            }
        }
    }

    // MARK: - Inloggen

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await auth.signIn(email: email, password: password)
            session = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Registreren

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await auth.signUp(email: email, password: password)
            session = response.session
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Uitloggen

    func signOut() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await auth.signOut()
            session = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
