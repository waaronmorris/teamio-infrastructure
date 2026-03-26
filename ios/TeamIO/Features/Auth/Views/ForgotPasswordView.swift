import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacingLG) {
                if isSuccess {
                    successView
                } else {
                    formView
                }
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var formView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 20)

            Text("Enter your email and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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

            if let error = authManager.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                submit()
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@") || isLoading)

            Spacer()
        }
    }

    private var successView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Check Your Email")
                .font(.title2.bold())

            Text("If an account exists with \(email), you'll receive a password reset link shortly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Spacer()
        }
    }

    private func submit() {
        isLoading = true
        Task {
            let success = await authManager.forgotPassword(email: email.trimmingCharacters(in: .whitespaces))
            isLoading = false
            if success {
                isSuccess = true
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environment(AuthManager())
}
