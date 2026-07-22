import Foundation
import SwiftData

/// One die inside a bag: its side count plus optional custom colors.
/// `nil` colors follow the theme (or the user's die color in Settings).
struct DieSpec: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var sides: Int = 6
    var faceHex: String? = nil
    var pipHex: String? = nil

    init(id: UUID = UUID(), sides: Int = 6, faceHex: String? = nil, pipHex: String? = nil) {
        self.id = id
        self.sides = sides
        self.faceHex = faceHex
        self.pipHex = pipHex
    }
}

/// A user-authored dice bag, stored with SwiftData and mirrored to CloudKit like
/// the player roster. Bags are grouped into named "dice boxes" purely for
/// organization; the dice themselves are encoded as a JSON blob so the schema
/// stays CloudKit-compatible (every property defaulted, no relationships).
@Model
final class DiceBag {
    var name: String = ""
    var boxName: String = DiceBag.defaultBox
    var diceData: Data = Data()
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    /// Stable identity that survives relaunches and CloudKit round-trips, used by
    /// the roller's selected-bag preference.
    var uuid: String = UUID().uuidString

    static let defaultBox = "Dice Box"

    init(name: String, boxName: String = DiceBag.defaultBox, dice: [DieSpec], sortIndex: Int = 0) {
        self.name = name
        self.boxName = boxName
        self.diceData = (try? JSONEncoder().encode(dice)) ?? Data()
        self.sortIndex = sortIndex
        self.createdAt = .now
        self.uuid = UUID().uuidString
    }

    var dice: [DieSpec] {
        get { (try? JSONDecoder().decode([DieSpec].self, from: diceData)) ?? [] }
        set { diceData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var selectionID: String { "custom:\(uuid)" }
}
