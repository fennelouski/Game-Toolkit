import Foundation
import SwiftData

/// A "game night": a named table of players with their own scores and turn order, e.g.
/// "Family Game Night" or "Catan – Fridays". Players created before any group exists live
/// at the built-in table (`Player.group == nil`), so nobody has to create a group to play.
///
/// Every stored property has a default value, the relationship is optional with an explicit
/// inverse, and there are no unique constraints — the CloudKit mirroring requirements.
@Model
final class PlayerGroup {
    var name: String = ""
    /// Stable identity used by `SettingsKey.activeGroupID`; `persistentModelID` can't be
    /// persisted across launches and CloudKit forbids unique constraints, so a plain UUID.
    var groupID: UUID = UUID()
    var createdAt: Date = Date.now

    /// Deleting a game night deletes its seats. People copied into other game nights are
    /// separate `Player` rows and are unaffected.
    @Relationship(deleteRule: .cascade, inverse: \Player.group)
    var players: [Player]? = nil

    init(name: String) {
        self.name = name
        self.groupID = UUID()
        self.createdAt = .now
    }
}
