import Foundation

enum SampleCards {
    static let handSize = 5

    static let black: [String] = [
        "I drink to forget ___.",
        "What's that smell?",
        "My therapist says I have an unhealthy obsession with ___.",
        "What's the next Hot Pocket flavor?",
        "In a pinch, ___ can be used as a flotation device.",
        "Scientists have discovered a new element: ___.",
        "___ — now that's a business idea.",
        "The new horror movie is called ___.",
        "I got 99 problems but ___ ain't one.",
        "What did I bring to show-and-tell?",
        "Step 1: ___. Step 2: ___. Step 3: Profit.",
        "What's the most passive-aggressive thing you own?",
        "This year's hot Halloween costume: ___.",
        "The secret ingredient is ___.",
        "What will finally end the internet?",
    ]

    static let white: [String] = [
        "Passive-aggressive sticky notes.",
        "A disappointing birthday party.",
        "The audacity.",
        "Free real estate.",
        "The entire country of Denmark.",
        "Forgetting someone's name mid-conversation.",
        "A live studio audience.",
        "Eating cereal with orange juice.",
        "Thoughts and prayers.",
        "An unexpected bill.",
        "The confidence of a mediocre man.",
        "A participation trophy.",
        "Pretending to be busy.",
        "A strongly worded letter.",
        "Going to bed at 9 pm.",
        "Unsolicited life advice.",
        "The void.",
        "Mild disappointment.",
        "A cheese-based solution.",
        "Corporate synergy.",
        "Another Zoom call.",
        "Sending the wrong emoji.",
        "Blaming the algorithm.",
        "The rent.",
        "Saying 'per my last email'.",
        "A spreadsheet with feelings.",
        "Just vibing.",
        "Screaming into a pillow.",
        "Technically, nothing illegal.",
        "Quiet quitting.",
        "An unsettling amount of eye contact.",
        "Telling everyone it's fine.",
        "A vague LinkedIn post.",
        "Someone else's dog.",
        "Saying 'no worries' and then worrying.",
        "Weaponized incompetence.",
        "The terms and conditions.",
        "A deeply suspicious casserole.",
        "One unread notification.",
        "The betrayal of store-brand cereal.",
        "Absolute banger of an email.",
        "Making it everyone's problem.",
        "A rogue Roomba.",
        "The audacity, again.",
        "Referring to yourself in the third person.",
        "A passive-aggressive fruit bowl.",
        "Aggressively mediocre Wi-Fi.",
        "Your browser history.",
        "A misplaced sense of urgency.",
        "The long pause before 'I mean…'",
    ]

    // Returns `handSize` random indices not already in `usedIndices`.
    static func dealHand(excluding usedIndices: Set<Int>) -> [Int] {
        let available = (0..<white.count).filter { !usedIndices.contains($0) }
        return Array(available.shuffled().prefix(handSize))
    }

    // Refill a player's hand up to `handSize`, avoiding indices already taken.
    static func refillHand(current: [Int], excluding usedIndices: Set<Int>) -> [Int] {
        let needed = handSize - current.count
        guard needed > 0 else { return current }
        let all = Set(usedIndices).union(current)
        let available = (0..<white.count).filter { !all.contains($0) }
        let newCards = Array(available.shuffled().prefix(needed))
        return current + newCards
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
