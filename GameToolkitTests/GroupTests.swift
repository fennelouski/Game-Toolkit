import Testing
import Foundation
import SwiftData
@testable import Game_Toolkit

// MARK: - Game nights (player groups)

@Suite("Player groups")
@MainActor
struct PlayerGroupTests {

    /// A fresh in-memory container so tests never touch the user's real store.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema([Player.self, PlayerGroup.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }

    private func fetchPlayers(_ context: ModelContext) throws -> [Player] {
        try context.fetch(FetchDescriptor<Player>())
    }

    @Test("The built-in table has the empty key; groups key by their UUID")
    func groupKeys() throws {
        let context = try makeContext()
        let group = Roster.createGroup(context, name: "Catan – Fridays")
        #expect(Roster.key(for: nil) == "")
        #expect(Roster.key(for: group) == group.groupID.uuidString)
    }

    @Test("Numbering, colors and sort order are scoped per game night")
    func addScopesPerGroup() throws {
        let context = try makeContext()
        Roster.add(context)
        Roster.add(context)
        let group = Roster.createGroup(context, name: "Catan")
        let first = Roster.add(context, group: group)

        // A fresh table starts over at Player 1 with the first palette slot.
        #expect(first.name == "Player 1")
        #expect(first.sortIndex == 0)
        #expect(first.paletteIndex == 0)
        #expect(first.group === group)
    }

    @Test("Members and playing filter by group and presence")
    func membershipFiltering() throws {
        let context = try makeContext()
        let a = Roster.add(context, name: "A")
        let b = Roster.add(context, name: "B")
        let group = Roster.createGroup(context, name: "Catan")
        let c = Roster.add(context, name: "C", group: group)
        b.isSittingOut = true

        let all = try fetchPlayers(context)
        #expect(Roster.members(all, inGroup: "").map(\.name) == ["A", "B"])
        #expect(Roster.playing(all, inGroup: "").map(\.name) == ["A"])
        #expect(Roster.members(all, inGroup: group.groupID.uuidString).map(\.name) == ["C"])
        _ = (a, c)
    }

    @Test("Adopting copies preferences, links identity, and starts scores fresh")
    func adoptCopiesPerson() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        source.scores = [5, 7]
        source.syncsPreferences = false
        let group = Roster.createGroup(context, name: "Catan")

        let copy = Roster.adopt(context, source: source, into: group)

        #expect(copy.name == "Maya")
        #expect(copy.colorHex == source.colorHex)
        #expect(copy.paletteIndex == source.paletteIndex)
        #expect(copy.syncsPreferences == false)
        #expect(copy.scores.isEmpty)
        #expect(source.personID != nil)
        #expect(copy.personID == source.personID)
        #expect(copy.group === group)
        // The original keeps its seat and its scores.
        #expect(source.group == nil)
        #expect(source.scores == [5, 7])
    }

    @Test("Preference edits propagate to synced seats only")
    func propagationHonorsOptOut() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let catan = Roster.createGroup(context, name: "Catan")
        let family = Roster.createGroup(context, name: "Family")
        let synced = Roster.adopt(context, source: source, into: catan)
        let optedOut = Roster.adopt(context, source: source, into: family)
        optedOut.syncsPreferences = false

        source.name = "Maya B."
        source.colorHex = "#123456"
        source.paletteIndex = nil
        Roster.propagatePreferences(context, from: source, players: try fetchPlayers(context))

        #expect(synced.name == "Maya B.")
        #expect(synced.colorHex == "#123456")
        #expect(synced.paletteIndex == nil)
        #expect(optedOut.name == "Maya")
    }

    @Test("An opted-out player pushes nothing")
    func optedOutPlayerPushesNothing() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let catan = Roster.createGroup(context, name: "Catan")
        let copy = Roster.adopt(context, source: source, into: catan)
        source.syncsPreferences = false

        source.name = "Renamed"
        Roster.propagatePreferences(context, from: source, players: try fetchPlayers(context))

        #expect(copy.name == "Maya")
    }

    @Test("Deleting a game night removes its seats but not the person elsewhere")
    func deleteGroupCascades() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let group = Roster.createGroup(context, name: "Catan")
        Roster.adopt(context, source: source, into: group)
        Roster.add(context, name: "Guest", group: group)
        #expect(try fetchPlayers(context).count == 3)

        Roster.deleteGroup(context, group: group)

        let remaining = try fetchPlayers(context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Maya")
        #expect(try context.fetch(FetchDescriptor<PlayerGroup>()).isEmpty)
    }

    @Test("Candidates dedupe people and exclude the current table")
    func candidateListing() throws {
        let context = try makeContext()
        let maya = Roster.add(context, name: "Maya")
        let jonah = Roster.add(context, name: "Jonah")
        let catan = Roster.createGroup(context, name: "Catan")
        Roster.adopt(context, source: maya, into: catan)

        let all = try fetchPlayers(context)
        // From Catan's point of view Maya already has a seat; only Jonah is offered.
        let forCatan = Roster.candidates(all, excludingGroup: catan.groupID.uuidString)
        #expect(forCatan.map(\.name) == ["Jonah"])
        // A brand-new group sees each person once, despite Maya's two seats.
        let forNew = Roster.candidates(all, excludingGroup: nil)
        #expect(forNew.map(\.name) == ["Jonah", "Maya"])
        _ = jonah
    }

    @Test("Seeding still populates the built-in table only when empty")
    func seedingUnaffectedByGroups() throws {
        let context = try makeContext()
        Roster.seedIfNeeded(context, existing: [])
        let players = try fetchPlayers(context)
        #expect(players.count == 2)
        #expect(players.allSatisfy { $0.group == nil })
    }
}
