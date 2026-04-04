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
    var waiverSigned = false
    var paymentCompleted = false

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

    func signWaiver() async {
        guard let regId = createdRegistrationId else { return }
        do {
            try await APIClient.shared.requestVoid(.signWaiver(regId))
            waiverSigned = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkout() async {
        guard let regId = createdRegistrationId else { return }
        struct CheckoutResponse: Decodable, Sendable {
            let checkout_url: String?
            let url: String?
        }
        do {
            let resp: CheckoutResponse = try await APIClient.shared.request(.registrationCheckout(regId))
            if let urlString = resp.checkout_url ?? resp.url, let url = URL(string: urlString) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
                paymentCompleted = true // Optimistic — Stripe webhook will confirm
            }
        } catch {
            self.error = error.localizedDescription
        }
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
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                Spacer(minLength: 40)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Registration Submitted!")
                    .font(.title2.bold())

                Text("Your registration is pending review. You'll be notified once it's approved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Next steps
                VStack(alignment: .leading, spacing: 16) {
                    // Step 1: Sign waiver
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.waiverSigned ? "checkmark.circle.fill" : "1.circle.fill")
                            .font(.title2)
                            .foregroundStyle(viewModel.waiverSigned ? .green : Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign Waiver")
                                .font(.subheadline.weight(.semibold))
                            Text(viewModel.waiverSigned ? "Completed" : "Required before playing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !viewModel.waiverSigned {
                            Button("Sign") {
                                Task { await viewModel.signWaiver() }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    // Step 2: Payment
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.paymentCompleted ? "checkmark.circle.fill" : "2.circle.fill")
                            .font(.title2)
                            .foregroundStyle(viewModel.paymentCompleted ? .green : Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Payment")
                                .font(.subheadline.weight(.semibold))
                            if viewModel.paymentCompleted {
                                Text("Paid")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Complete payment to finalize registration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if !viewModel.paymentCompleted {
                            Button("Pay Now") {
                                Task { await viewModel.checkout() }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    // Step 3: Approval
                    HStack(spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Commissioner Approval")
                                .font(.subheadline.weight(.semibold))
                            Text("Pending review by your league")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: "Pending", color: .orange)
                    }
                }
                .cardStyle()

                VStack(spacing: 12) {
                    Button("Register Another") {
                        viewModel.isSuccess = false
                        viewModel.selectedPlayerId = nil
                        viewModel.createdRegistrationId = nil
                        viewModel.waiverSigned = false
                        viewModel.paymentCompleted = false
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

#Preview {
    RegistrationView()
        .environment(AuthManager())
}
