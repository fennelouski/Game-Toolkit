#if os(iOS) && !targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

/// External-display support: when the phone is mirrored to an Apple TV (or plugged into
/// any screen), the app takes over the big screen with a purpose-built scoreboard
/// instead of a letterboxed copy of the phone.
///
/// With the toggle off — or before any window is attached — the system keeps ordinary
/// mirroring, so this is strictly an enhancement.
final class ExternalDisplayAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
            configuration.delegateClass = ExternalDisplaySceneDelegate.self
        }
        return configuration
    }
}

final class ExternalDisplaySceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    private weak var windowScene: UIWindowScene?
    private var settingsObserver: NSObjectProtocol?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        self.windowScene = windowScene
        updateWindow()
        // Follow the Settings toggle live while the screen stays connected.
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateWindow() }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
        settingsObserver = nil
        window = nil
    }

    /// Creates or tears down the scoreboard window to match the Settings toggle.
    /// With no window attached, the system falls back to plain mirroring.
    private func updateWindow() {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.externalScoreboard) as? Bool ?? true
        if enabled, window == nil, let windowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ExternalScoreboardRoot())
            self.window = window
            window.isHidden = false
        } else if !enabled, window != nil {
            window?.isHidden = true
            window = nil
        }
    }
}
#endif

import SwiftUI
import SwiftData

/// Wires the scoreboard to the shared data container and the active theme. This is the
/// root of the external window, but it also renders in-app for the DEBUG preview.
struct ExternalScoreboardRoot: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        ExternalScoreboardView()
            .environment(\.palette, themeManager.current.palette(for: colorScheme))
            .modelContainer(AppContainer.shared)
    }
}

/// The TV scoreboard: the whole table's standings, legible from the couch.
/// Read-only by design — the phone stays the controller.
struct ExternalScoreboardView: View {
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var players: [Player]

    private var rounds: Int { Roster.roundCount(players) }
    private var leadingTotal: Int? {
        guard rounds > 0 else { return nil }
        return players.map(\.total).max()
    }

    /// Adapts from one column on a narrow debug preview up to a full row on a TV.
    private let columns = [GridItem(.adaptive(minimum: 270, maximum: 440), spacing: 24)]

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 30) {
                header

                if players.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(players) { player in
                            playerCard(player)
                        }
                    }
                    .frame(maxWidth: 1500)
                }

                Spacer(minLength: 0)
            }
            .padding(48)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Scorecard")
                .font(.display(52))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text(rounds == 0 ? "Waiting for the first round" : "After round \(rounds)")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: 1500)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                FeltSurface(felt: palette.table, cornerRadius: 30)
                    .frame(width: 420, height: 240)
                HStack(spacing: 24) {
                    DieView(value: 5, sides: 6, spin: 0, face: palette.diceFace, pip: palette.dicePip, seed: 0)
                        .frame(width: 110, height: 110)
                    DieView(value: 3, sides: 6, spin: 0, face: palette.diceFace, pip: palette.dicePip, seed: 5)
                        .frame(width: 110, height: 110)
                }
            }
            Text("Add players on your phone and the scoreboard appears here.")
                .font(.system(size: 24))
                .foregroundStyle(palette.textSecondary)
            Spacer()
        }
    }

    private func playerCard(_ player: Player) -> some View {
        let color = player.color(in: palette)
        let isLeader = rounds > 0 && player.total == leadingTotal
        return VStack(spacing: 14) {
            if isLeader {
                Image(systemName: "crown.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(palette.warning)
            } else {
                // Keeps every card the same height whether or not the crown is showing.
                Color.clear.frame(height: 36)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.gradient)
                    Text(String((player.name.isEmpty ? "?" : player.name).prefix(1)).uppercased())
                        .font(.display(26))
                        .foregroundStyle(color.readableForeground)
                }
                .frame(width: 52, height: 52)

                Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Text("\(player.total)")
                .font(.display(96))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.35)
                .foregroundStyle(isLeader ? palette.textPrimary : palette.textSecondary)
                .contentTransition(.numericText())

            if rounds > 0 {
                Text(lastRoundSummary(player))
                    .font(.system(size: 20, weight: .medium))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background {
            let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
            shape
                .fill(palette.surface)
                .overlay {
                    shape.strokeBorder(isLeader ? palette.warning : palette.textSecondary.opacity(0.18),
                                       lineWidth: isLeader ? 3 : 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 14, y: 7)
        }
        .animation(.snappy, value: player.total)
    }

    private func lastRoundSummary(_ player: Player) -> String {
        let last = player.score(inRound: rounds - 1)
        return last >= 0 ? "+\(last) last round" : "\(last) last round"
    }
}

#Preview {
    ExternalScoreboardRoot()
}
