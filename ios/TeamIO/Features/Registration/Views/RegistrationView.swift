import SwiftUI

@Observable
@MainActor
final class RegistrationViewModel {
    var seasons: [Season] = []
    var children: [Player] = []
    var selectedSeasonId: String?
    var selectedPlayerId: String?
    var registrationMode: RegistrationMode = .child
    var isLoading = false
    var isSubmitting = false
    var error: String?
    var isSuccess = false
    var createdRegistrationId: String?

    enum RegistrationMode: String, CaseIterable {
        case myself = "Register Myself"
        case child = "Register My Child"
    }

    func loadInitial(userId: String) async {
        isLoading = true
        do {
            async let seasonsTask: [Season] = APIClient.shared.request(.seasons())
            async let childrenTask: [Player] = APIClient.shared.request(
                .playerGuardians(userId), queryItems: [URLQueryItem(name: "role", value: "guardian")]
            )

            let loadedSeasons = try await seasonsTask
            self.seasons = loadedSeasons.filter {
                $0.status == .registration || $0.status == .registration_open || $0.status == .in_progress
            }
            self.children = try await childrenTask

            if let first = seasons.first {
                selectedSeasonId = first.id
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submit(userId: String) async {
        guard let seasonId = selectedSeasonId else { return }

        let playerId: String?
        if registrationMode == .myself {
            playerId = userId
        } else {
            playerId = selectedPlayerId
        }
        guard let playerId else {
            error = "Please select a player"
            return
        }

        isSubmitting = true
        error = nil

        struct RegistrationRequest: Encodable, Sendable {
            let season_id: String
            let player_id: String
        }

        do {
            let request = RegistrationRequest(season_id: seasonId, player_id: playerId)
            let reg: Registration = try await APIClient.shared.request(.createRegistration(), body: request)
            createdRegistrationId = reg.id
            isSuccess = true
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}

struct RegistrationView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = RegistrationViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Registration")
            .task {
                if let userId = authManager.currentUser?.id {
                    await viewModel.loadInitial(userId: userId)
                }
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                // Mode picker
                Picker("Mode", selection: $viewModel.registrationMode) {
                    ForEach(RegistrationViewModel.RegistrationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // Season selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Season")
                        .font(.subheadline.weight(.medium))

                    if viewModel.seasons.isEmpty {
                        Text("No seasons open for registration")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Season", selection: Binding(
                            get: { viewModel.selectedSeasonId ?? "" },
                            set: { viewModel.selectedSeasonId = $0.isEmpty ? nil : $0 }
                        )) {
                            ForEach(viewModel.seasons) { season in
                                Text("\(season.name) (\(season.status.displayName))").tag(season.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .cardStyle()

                // Player selection
                if viewModel.registrationMode == .child {
                    childSelector
                } else if let user = authManager.currentUser {
                    selfRegistrationCard(user: user)
                }

                // Error
                if let error = viewModel.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Submit
                Button {
                    Task {
                        if let userId = authManager.currentUser?.id {
                            await viewModel.submit(userId: userId)
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Registration")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    viewModel.selectedSeasonId == nil ||
                    viewModel.isSubmitting ||
                    (viewModel.registrationMode == .child && viewModel.selectedPlayerId == nil)
                )
            }
            .padding()
        }
    }

    private var childSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Child")
                .font(.subheadline.weight(.medium))

            if viewModel.children.isEmpty {
                Text("No children linked to your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.children) { child in
                    Button {
                        viewModel.selectedPlayerId = child.id
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: child.displayName, size: 40)
                            VStack(alignment: .leading) {
                                Text(child.displayName)
                                    .font(.subheadline.weight(.medium))
                                if let dob = child.date_of_birth {
                                    Text("DOB: \(dob.shortDate)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if viewModel.selectedPlayerId == child.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private func selfRegistrationCard(user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: user.fullName, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.subheadline.weight(.semibold))
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
        }
        .cardStyle()
    }

    private var successView: some View {
        VStack(spacing: AppTheme.spacingLG) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Registration Submitted!")
                .font(.title2.bold())

            Text("Your registration is pending review. You'll be notified once it's approved.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button("Register Another") {
                    viewModel.isSuccess = false
                    viewModel.selectedPlayerId = nil
                    viewModel.createdRegistrationId = nil
                }
                .buttonStyle(.borderedProminent)

                Button("Done") {
                    // Pop to dashboard
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    RegistrationView()
        .environment(AuthManager())
}
