import SwiftUI

@Observable
@MainActor
final class PaymentsViewModel {
    var transactions: [PaymentTransaction] = []
    var isLoading = false
    var error: String?

    var totalAmount: Double {
        transactions
            .filter { $0.status == "completed" }
            .compactMap { $0.amount_cents }
            .reduce(0) { $0 + Double($1) / 100.0 }
    }

    var pendingCount: Int {
        transactions.filter { $0.status == "pending" }.count
    }

    func load() async {
        isLoading = true
        do {
            let response: PaymentsResponse = try await APIClient.shared.request(.payments())
            transactions = response.transactions
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct PaymentsView: View {
    @State private var viewModel = PaymentsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "dollarsign.circle.fill",
                            value: String(format: "$%.2f", viewModel.totalAmount),
                            label: "Total Paid"
                        )
                        StatCard(
                            icon: "clock.fill",
                            value: "\(viewModel.pendingCount)",
                            label: "Pending"
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transaction History")
                            .font(.headline)

                        if viewModel.isLoading && viewModel.transactions.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.transactions.isEmpty {
                            Text("No transactions yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.transactions) { txn in
                                    TransactionRow(transaction: txn)
                                    Divider()
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding()
            }
            .navigationTitle("Payments")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
        }
    }
}

struct TransactionRow: View {
    let transaction: PaymentTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.payer_name ?? "Payment")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    if let provider = transaction.provider {
                        Text(provider.capitalized)
                    }
                    Text(transaction.created_at?.shortDate ?? "")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amountDisplay)
                    .font(.subheadline.weight(.bold))
                if let status = transaction.status {
                    StatusBadge(text: status.capitalized, color: statusColor)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var statusIcon: String {
        switch transaction.status {
        case "completed": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "failed": return "xmark.circle.fill"
        case "refunded": return "arrow.uturn.backward.circle.fill"
        default: return "circle"
        }
    }

    private var statusColor: Color {
        switch transaction.status {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        case "refunded": return .secondary
        default: return .secondary
        }
    }
}

#Preview {
    PaymentsView()
}
