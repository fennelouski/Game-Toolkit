import Foundation
import SwiftData
import Testing
@testable import Game_Toolkit

@MainActor
struct PersistenceTests {
    @Test func preservesUnreadableStoreAndCanRetry() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("games.store")
        let original = Data("unreadable existing store".utf8)
        try original.write(to: url)
        let store = AppContainer(configuration: ModelConfiguration(url: url, cloudKitDatabase: .none))
        #expect(store.container == nil)
        #expect(try Data(contentsOf: url) == original)
        store.load()
        #expect(store.container == nil)
        #expect(try Data(contentsOf: url) == original)

        // Simulate the cause being resolved without replacing a real user's data.
        try FileManager.default.removeItem(at: url)
        store.load()
        let container = try #require(store.container)
        let player = Player(name: "Alex")
        player.scores = [5, 8]
        container.mainContext.insert(player)
        try container.mainContext.save()
        let reopened = AppContainer(configuration: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let players = try #require(reopened.container).mainContext.fetch(FetchDescriptor<Player>())
        #expect(players.count == 1)
        #expect(players.first?.scores == [5, 8])
    }
}
