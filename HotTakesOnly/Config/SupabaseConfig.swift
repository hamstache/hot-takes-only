import Foundation

enum SupabaseConfig {
    static let url: URL = {
        let raw = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        guard let url = URL(string: raw), !raw.isEmpty else {
            fatalError("SUPABASE_URL env var missing or invalid — set it in the Xcode scheme (Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables)")
        }
        return url
    }()

    static let anonKey: String = {
        let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        precondition(!key.isEmpty, "SUPABASE_ANON_KEY env var missing — set it in the Xcode scheme")
        return key
    }()
}
