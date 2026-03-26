import SwiftUI

struct CalendarSubscription: Codable, Identifiable, Sendable {
    let id: String
    let name: String?
    let subscription_type: String
    let resource_name: String?
    let feed_url: String
    let event_types: [String]?
    let include_cancelled: Bool?
    let is_active: Bool
    let access_count: Int?
    let last_accessed_at: Date?
    let created_at: Date?
}

@Observable
@MainActor
final class CalendarViewModel {
    var subscriptions: [CalendarSubscription] = []
    var isLoading = false
    var error: String?
    var showCreateSheet = false

    func load() async {
        isLoading = true
        do {
            let response: SubscriptionsResponse = try await APIClient.shared.request(.calendarSubscriptions())
            subscriptions = response.subscriptions
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ id: String) async {
        do {
            try await APIClient.shared.requestVoid(.deleteCalendarSubscription(id))
            subscriptions.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func regenerateToken(_ id: String) async {
        do {
            let updated: CalendarSubscription = try await APIClient.shared.request(
                .regenerateCalendarToken(id)
            )
            if let idx = subscriptions.firstIndex(where: { $0.id == id }) {
                subscriptions[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct CalendarSubscriptionsView: View {
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.subscriptions.isEmpty {
                    ProgressView("Loading subscriptions...")
                } else if viewModel.subscriptions.isEmpty {
                    ContentUnavailableView(
                        "No Calendar Subscriptions",
                        systemImage: "calendar.badge.plus",
                        description: Text("Subscribe to calendars to sync events with your device.")
                    )
                } else {
                    List {
                        ForEach(viewModel.subscriptions) { sub in
                            SubscriptionRow(
                                subscription: sub,
                                onRegenerate: { Task { await viewModel.regenerateToken(sub.id) } },
                                onDelete: { Task { await viewModel.delete(sub.id) } }
                            )
                        }

                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to Subscribe")
                                    .font(.subheadline.weight(.semibold))
                                Text("Copy the feed URL and add it to your calendar app:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Label("Google Calendar: Other calendars > From URL", systemImage: "globe")
                                Label("Apple Calendar: File > New Calendar Subscription", systemImage: "apple.logo")
                                Label("Outlook: Add calendar > From internet", systemImage: "envelope")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Calendar Sync")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateSubscriptionSheet {
                    Task { await viewModel.load() }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

struct SubscriptionRow: View {
    let subscription: CalendarSubscription
    let onRegenerate: () -> Void
    let onDelete: () -> Void
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subscription.name ?? subscription.subscription_type.capitalized)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(
                    text: subscription.is_active ? "Active" : "Paused",
                    color: subscription.is_active ? .green : .orange
                )
            }

            if let resourceName = subscription.resource_name {
                Text(resourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Feed URL
            HStack {
                Text(subscription.feed_url)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = subscription.feed_url
                    showCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        showCopied = false
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            if let types = subscription.event_types, !types.isEmpty {
                HStack(spacing: 4) {
                    ForEach(types, id: \.self) { type in
                        Text(type.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }

            HStack {
                if let count = subscription.access_count {
                    Text("\(count) syncs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Regenerate", systemImage: "arrow.triangle.2.circlepath") {
                    onRegenerate()
                }
                .font(.caption2)
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
                .font(.caption2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateSubscriptionSheet: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var subscriptionType = "user_teams"
    @State private var selectedEventTypes: Set<String> = ["game", "practice"]
    @State private var includeCancelled = false
    @State private var isSaving = false

    private let types = ["user_teams", "team", "league", "field"]
    private let eventTypes = ["game", "practice", "scrimmage", "tournament", "meeting", "other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (optional)", text: $name)
                    Picker("Type", selection: $subscriptionType) {
                        ForEach(types, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                        }
                    }
                }

                Section("Event Types") {
                    ForEach(eventTypes, id: \.self) { type in
                        Toggle(type.capitalized, isOn: Binding(
                            get: { selectedEventTypes.contains(type) },
                            set: { isOn in
                                if isOn { selectedEventTypes.insert(type) }
                                else { selectedEventTypes.remove(type) }
                            }
                        ))
                    }
                }

                Section {
                    Toggle("Include Cancelled Events", isOn: $includeCancelled)
                }
            }
            .navigationTitle("New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func create() {
        isSaving = true
        Task {
            struct CreateRequest: Encodable, Sendable {
                let name: String?
                let subscription_type: String
                let event_types: [String]
                let include_cancelled: Bool
            }
            let request = CreateRequest(
                name: name.isEmpty ? nil : name,
                subscription_type: subscriptionType,
                event_types: Array(selectedEventTypes),
                include_cancelled: includeCancelled
            )
            do {
                let _: CalendarSubscription = try await APIClient.shared.request(
                    .createCalendarSubscription(), body: request
                )
                onCreated()
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}

#Preview {
    CalendarSubscriptionsView()
}
