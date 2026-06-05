import Foundation

struct Submission: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var roomId: UUID
    var playerId: UUID
    var roundNumber: Int
    var cardIndex: Int
    var isWinner: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case roomId      = "room_id"
        case playerId    = "player_id"
        case roundNumber = "round_number"
        case cardIndex   = "card_index"
        case isWinner    = "is_winner"
        case createdAt   = "created_at"
    }
}

struct NewSubmission: Encodable {
    let roomId: UUID
    let playerId: UUID
    let roundNumber: Int
    let cardIndex: Int

    enum CodingKeys: String, CodingKey {
        case roomId      = "room_id"
        case playerId    = "player_id"
        case roundNumber = "round_number"
        case cardIndex   = "card_index"
    }
}
