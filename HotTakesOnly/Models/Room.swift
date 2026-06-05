import Foundation

struct Room: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var code: String
    var status: GamePhase
    var currentRound: Int
    var judgeIndex: Int
    var blackCardIndex: Int
    var maxRounds: Int
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, code, status
        case currentRound   = "current_round"
        case judgeIndex     = "judge_index"
        case blackCardIndex = "black_card_index"
        case maxRounds      = "max_rounds"
        case createdAt      = "created_at"
    }
}

enum GamePhase: String, Codable, Sendable {
    case waiting
    case submitting
    case judging
    case roundOver  = "round_over"
    case finished
}

// Payload used when inserting a new room — omits server-set fields.
struct NewRoom: Encodable {
    let code: String
    let status: String = GamePhase.waiting.rawValue
    let maxRounds: Int

    enum CodingKeys: String, CodingKey {
        case code, status
        case maxRounds = "max_rounds"
    }
}
