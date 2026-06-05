import Foundation

struct Player: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var roomId: UUID
    var displayName: String
    var score: Int
    var isHost: Bool
    var isReady: Bool
    var handIndices: [Int]
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, score
        case roomId      = "room_id"
        case displayName = "display_name"
        case isHost      = "is_host"
        case isReady     = "is_ready"
        case handIndices = "hand_indices"
        case createdAt   = "created_at"
    }
}

struct NewPlayer: Encodable {
    let roomId: UUID
    let displayName: String
    let isHost: Bool
    let handIndices: [Int] = []

    enum CodingKeys: String, CodingKey {
        case roomId      = "room_id"
        case displayName = "display_name"
        case isHost      = "is_host"
        case handIndices = "hand_indices"
    }
}
