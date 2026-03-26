import SwiftUI

@Observable
@MainActor
final class DraftRoomViewModel {
    var draft: Draft?
    var availablePlayers: [DraftPlayer] = []
    var picks: [DraftPick] = []
    var turns: [DraftTurn] = []
    var isLoading = false
    var error: String?
    var searchText = ""
    var selectedPlayer: DraftPlayer?
    var webSocketTask: URLSessionWebSocketTask?

    var filteredPlayers: [DraftPlayer] {
        if searchText.isEmpty { return availablePlayers.filter { $0.is_picked != true } }
        return availablePlayers
            .filter { $0.is_picked != true }
            .filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var currentTurn: DraftTurn? {
        turns.first { $0.status == "current" || $0.status == "pending" }
    }

    var isMyTurn: Bool {
        currentTurn != nil
    }

    func load(draftId: String) async {
        isLoading = true
        do {
            async let draftTask: Draft = APIClient.shared.request(.draft(draftId))
            async let playersTask: [DraftPlayer] = APIClient.shared.request(.draftPlayers(draftId))
            async let picksTask: [DraftPick] = APIClient.shared.request(.draftPicks(draftId))
            async let turnsTask: [DraftTurn] = APIClient.shared.request(.draftTurns(draftId))

            self.draft = try await draftTask
            self.availablePlayers = try await playersTask
            self.picks = try await picksTask
            self.turns = try await turnsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func pickPlayer(draftId: String) async {
        guard let player = selectedPlayer else { return }
        struct PickRequest: Encodable, Sendable {
            let player_id: String
        }
        do {
            let _: DraftPick = try await APIClient.shared.request(
                .makeDraftPick(draftId), body: PickRequest(player_id: player.id)
            )
            selectedPlayer = nil
            await load(draftId: draftId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func skipTurn(draftId: String) async {
        do {
            try await APIClient.shared.requestVoid(.skipDraftTurn(draftId))
            await load(draftId: draftId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func undoPick(draftId: String) async {
        do {
            try await APIClient.shared.requestVoid(.undoDraftPick(draftId))
            await load(draftId: draftId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func togglePause(draftId: String) async {
        guard let draft else { return }
        do {
            if draft.status == .paused {
                try await APIClient.shared.requestVoid(.resumeDraft(draftId))
            } else {
                try await APIClient.shared.requestVoid(.pauseDraft(draftId))
            }
            await load(draftId: draftId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func connectWebSocket(draftId: String) {
        #if DEBUG
        let wsURL = "ws://localhost:8082/ws/drafts/\(draftId)"
        #else
        let wsURL = "wss://api.getteamio.com/ws/drafts/\(draftId)"
        #endif

        guard let url = URL(string: wsURL) else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessages(draftId: draftId)
    }

    private func receiveMessages(draftId: String) {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    await self?.load(draftId: draftId)
                    self?.receiveMessages(draftId: draftId)
                case .failure:
                    break
                }
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}

struct DraftRoomView: View {
    let draftId: String
    @State private var viewModel = DraftRoomViewModel()

    var body: some View {
        Group {
            if let draft = viewModel.draft {
                VStack(spacing: 0) {
                    draftHeader(draft)
                    Divider()

                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            if draft.status == .in_progress || draft.status == .paused {
                                controlBar(draft)
                            }
                            turnQueueSection
                            playerPoolSection
                            draftBoardSection
                        }
                        .padding()
                    }
                }
            } else if viewModel.isLoading {
                ProgressView("Loading draft...")
            } else if let error = viewModel.error {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            }
        }
        .navigationTitle("Draft Room")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(draftId: draftId)
        }
        .task {
            await viewModel.load(draftId: draftId)
            viewModel.connectWebSocket(draftId: draftId)
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }

    private func draftHeader(_ draft: Draft) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.name ?? "Draft")
                    .font(.headline)
                Text("Round \(draft.current_round ?? 1) / Pick \(draft.current_pick ?? 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(text: draft.status.displayName, color: draft.status == .in_progress ? .green : draft.status == .paused ? .orange : .secondary)

            if draft.status.isLive {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }

    private func controlBar(_ draft: Draft) -> some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.togglePause(draftId: draftId) }
            } label: {
                Label(
                    draft.status == .paused ? "Resume" : "Pause",
                    systemImage: draft.status == .paused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(.bordered)

            Button {
                Task { await viewModel.undoPick(draftId: draftId) }
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.picks.isEmpty)

            Button {
                Task { await viewModel.skipTurn(draftId: draftId) }
            } label: {
                Label("Skip", systemImage: "forward.fill")
            }
            .buttonStyle(.bordered)

            Spacer()

            if let player = viewModel.selectedPlayer {
                Button {
                    Task { await viewModel.pickPlayer(draftId: draftId) }
                } label: {
                    Label("Pick \(player.displayName)", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var turnQueueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Turn Queue")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.turns.prefix(8)) { turn in
                        VStack(spacing: 4) {
                            Text(turn.team_name ?? "Team")
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                            Text("R\(turn.round)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            turn.status == "current"
                                ? Color.accentColor.opacity(0.15)
                                : Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(turn.status == "current" ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .cardStyle()
    }

    private var playerPoolSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Available Players")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(viewModel.filteredPlayers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Search players...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredPlayers.prefix(20)) { player in
                    Button {
                        viewModel.selectedPlayer = player
                    } label: {
                        HStack(spacing: 10) {
                            Text(player.jersey_number ?? "--")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .frame(width: 28)
                            Text(player.displayName)
                                .font(.subheadline)
                            if let pos = player.position {
                                Text(pos)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedPlayer?.id == player.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var draftBoardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Draft Board")
                .font(.subheadline.weight(.semibold))

            if viewModel.picks.isEmpty {
                Text("No picks yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.picks.sorted { $0.pick_number < $1.pick_number }) { pick in
                        HStack(spacing: 10) {
                            Text("\(pick.round).\(pick.pick_number)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .frame(width: 36)

                            if pick.is_skipped == true {
                                Text("Skipped")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            } else {
                                Text(pick.player_name ?? "Unknown")
                                    .font(.subheadline)
                            }

                            Spacer()

                            Text(pick.team_name ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct DraftListView: View {
    @State private var drafts: [Draft] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && drafts.isEmpty {
                    ProgressView("Loading drafts...")
                } else if drafts.isEmpty {
                    ContentUnavailableView("No Drafts", systemImage: "list.clipboard", description: Text("No drafts have been created yet."))
                } else {
                    List(drafts) { draft in
                        NavigationLink {
                            DraftRoomView(draftId: draft.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(draft.name ?? "Draft")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Rounds: \(draft.total_rounds ?? 0)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(text: draft.status.displayName, color: draft.status == .completed ? .green : draft.status.isLive ? .orange : .blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Drafts")
            .refreshable {
                do { let response: DraftsResponse = try await APIClient.shared.request(.drafts()); drafts = response.drafts } catch {}
            }
            .task {
                isLoading = true
                do {
                    let response: DraftsResponse = try await APIClient.shared.request(.drafts())
                    drafts = response.drafts
                } catch {}
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        DraftRoomView(draftId: "test")
    }
}
