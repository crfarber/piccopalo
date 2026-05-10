import Foundation
import Supabase

/// Centrale Supabase-client. Gebruik `SupabaseManager.shared.client` voor alle Supabase-aanroepen.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://wzqyrupndkbcoluslejm.supabase.co")!,
            supabaseKey: "sb_publishable_bhYF0Z8FDJx5Nd8WBXjdUg_AYBEeu_x"
        )
    }
}
