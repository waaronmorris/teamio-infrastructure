import SwiftUI

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let type: SearchResultType
    let icon: String

    enum SearchResultType: String {
        case user, season, event, team
    }
}

@Observable
@MainActor
final class SearchViewModel {
    var query = ""
    var results: [SearchResult] = []
    var isSearching = false

    func search() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else {
            results = []
            return
        }

        isSearching = true

        var allResults: [SearchResult] = []

        // Search users
        do {
            let response: UsersResponse = try await APIClient.shared.request(
                .searchUsers(),
                queryItems: [URLQueryItem(name: "search", value: q), URLQueryItem(name: "per_page", value: "3")]
            )
            allResults += response.users.map {
                SearchResult(id: $0.id, title: $0.fullName, subtitle: "\($0.role.displayName) - \($0.email)", type: .user, icon: "person.fill")
            }
        } catch {}

        // Search teams
        do {
            let response: TeamsResponse = try await APIClient.shared.request(
                .teams(),
                queryItems: [URLQueryItem(name: "search", value: q), URLQueryItem(name: "per_page", value: "3")]
            )
            allResults += response.teams.map {
                SearchResult(id: $0.id, title: $0.name, subtitle: $0.season_name ?? "", type: .team, icon: "person.3.fill")
            }
        } catch {}

        // Search events
        do {
            let response: EventsResponse = try await APIClient.shared.request(
                .events(),
                queryItems: [URLQueryItem(name: "search", value: q), URLQueryItem(name: "per_page", value: "3")]
            )
            allResults += response.events.map {
                SearchResult(id: $0.id, title: $0.displayTitle, subtitle: $0.start_time.shortDateTime, type: .event, icon: "calendar")
            }
        } catch {}

        results = allResults
        isSearching = false
    }
}

struct SearchSheet: View {
    @State private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search players, teams, events...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                            viewModel.results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                Divider()

                // Results
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.results.isEmpty && viewModel.query.count >= 2 {
                    Spacer()
                    ContentUnavailableView.search(text: viewModel.query)
                    Spacer()
                } else if viewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("Type at least 2 characters to search")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List(viewModel.results) { result in
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: result.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .font(.subheadline.weight(.medium))
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                StatusBadge(text: result.type.rawValue.capitalized, color: .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.query) {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    await viewModel.search()
                }
            }
        }
    }
}

#Preview {
    SearchSheet()
}
