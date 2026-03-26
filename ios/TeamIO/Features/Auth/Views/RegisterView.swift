import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.title.bold())
                    Text("Join TeamIO to manage your leagues")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: AppTheme.spacingMD) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("First Name")
                                .font(.subheadline.weight(.medium))
                            TextField("First", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.givenName)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last Name")
                                .font(.subheadline.weight(.medium))
                            TextField("Last", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.familyName)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                        TextField("you@example.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                        SecureField("At least 8 characters", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.subheadline.weight(.medium))
                        SecureField("Re-enter password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }

                    if !passwordsMatch && !confirmPassword.isEmpty {
                        Label("Passwords don't match", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let error = authManager.error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        register()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || isLoading)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        passwordsMatch
    }

    private func register() {
        isLoading = true
        Task {
            await authManager.register(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthManager())
    }
}
