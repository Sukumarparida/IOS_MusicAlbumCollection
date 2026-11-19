import Foundation

/// Protocol defining persistence operations for encodable and decodable data.
protocol StorageServiceProtocol: Sendable {
    func load<T: Decodable>(forKey key: String) -> T?
    func save<T: Encodable>(_ value: T, forKey key: String)
    func remove(forKey key: String)
}
