import SwiftUI

enum RecipientType: String, CaseIterable {
    case league = "All Teams in a League"
    case team = "Team Parents"
    case individual = "Individual"
}

@Observable
@MainActor
final class ComposeMessageViewModel {
    var recipientType: RecipientType = .team
    var selectedLeagueId: String = ""
    var selectedTeamId: String = ""
    var userSearchText = ""
    var selectedUserId: String = ""
    var selectedUserName: String = ""
    var subject = ""
    var body = ""
    var priority: String = "normal"
    var leagues: [League] = []
    var teams: [Team] = []
    var searchedUsers: [User] = []
    var isSending = false
    var error: String?

    var isValid: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidRecipient
    }

    var hasValidRecipient: Bool {
        switch recipientType {
        case .league: return !selectedLeagueId.isEmpty
        case .team: return !selectedTeamId.isEmpty
        case .individual: return !selectedUserId.isEmpty
        }
    }

    func loadOptions() async {
        do {
            let resp: LeaguesResponse = try await APIClient.shared.request(.leagues())
            self.leagues = resp.leagues
        } catch {
            print("[Compose] leagues error: \(error)")
        }

        do {
            let resp: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
            self.teams = resp.teams
        } catch {
            print("[Compose] teams error: \(error)")
        }
    }

    func searchUsers() async {
        let q = userSearchText.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { searchedUsers = []; return }
        do {
            let response: UsersResponse = try await APIClient.shared.request(
                .searchUsers(),
                queryItems: [URLQueryItem(name: "search", value: q), URLQueryItem(name: "per_page", value: "10")]
            )
            searchedUsers = response.users
        } catch {}
    }

    func send() async -> Bool {
        isSending = true
        error = nil

        struct SendPayload: Encodable, Sendable {
            let message_type: String
            let subject: String?
            let body: String
            let priority: String
            let scope_type: String?
            let scope_id: String?
            let recipient_ids: [String]?
        }

        let payload: SendPayload
        switch recipientType {
        case .league:
            payload = SendPayload(message_type: "announcement", subject: subject.isEmpty ? nil : subject, body: body, priority: priority, scope_type: "league", scope_id: selectedLeagueId, recipient_ids: nil)
        case .team:
            payload = SendPayload(message_type: "announcement", subject: subject.isEmpty ? nil : subject, body: body, priority: priority, scope_type: "team", scope_id: selectedTeamId, recipient_ids: nil)
        case .individual:
            payload = SendPayload(message_type: "direct", subject: subject.isEmpty ? nil : subject, body: body, priority: priority, scope_type: nil, scope_id: nil, recipient_ids: [selectedUserId])
        }

        do {
            let _: Message = try await APIClient.shared.request(.sendMessage(), body: payload)
            isSending = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSending = false
            return false
        }
    }
}

struct ComposeMessageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ComposeMessageViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    Picker("Send to", selection: $viewModel.recipientType) {
                        ForEach(RecipientType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    switch viewModel.recipientType {
                    case .league:
                        Picker("League", selection: $viewModel.selectedLeagueId) {
                            Text("Select league").tag("")
                            ForEach(viewModel.leagues) { league in
                                Text(league.name).tag(league.id)
                            }
                        }
                    case .team:
                        Picker("Team", selection: $viewModel.selectedTeamId) {
                            Text("Select team").tag("")
                            ForEach(viewModel.teams) { team in
                                Text(team.name).tag(team.id)
                            }
                        }
                    case .individual:
                        TextField("Search users...", text: $viewModel.userSearchText)
                            .onChange(of: viewModel.userSearchText) {
                                Task { await viewModel.searchUsers() }
                            }
                        if !viewModel.searchedUsers.isEmpty {
                            ForEach(viewModel.searchedUsers) { user in
                                Button {
                                    viewModel.selectedUserId = user.id
                                    viewModel.selectedUserName = user.fullName
                                    viewModel.userSearchText = user.fullName
                                    viewModel.searchedUsers = []
                                } label: {
                                    HStack {
                                        Text(user.fullName)
                                        Spacer()
                                        Text(user.role.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Message") {
                    Picker("Priority", selection: $viewModel.priority) {
                        Text("Normal").tag("normal")
                        Text("Urgent").tag("urgent")
                        Text("Emergency").tag("emergency")
                    }

                    TextField("Subject (optional)", text: $viewModel.subject)

                    TextField("Message", text: $viewModel.body, axis: .vertical)
                        .lineLimit(6...12)
                }

                if let error = viewModel.error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            if await viewModel.send() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSending)
                }
            }
            .task {
                await viewModel.loadOptions()
            }
        }
    }
}

#Preview {
    ComposeMessageSheet()
}
