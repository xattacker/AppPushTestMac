import Foundation

/// Loads/saves the small JSON "last used values" records that each window restores on open.
/// Mirrors the `AppProperties.AppPath` + `Xattacker.Utility.Json.JsonUtility` file persistence
/// used by the original WPF windows, but stores under the sandbox-safe
/// `Application Support/AppPushTestMac` directory instead of the app's install folder.
enum RecordStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("AppPushTestMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func load<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, filename: String) {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
