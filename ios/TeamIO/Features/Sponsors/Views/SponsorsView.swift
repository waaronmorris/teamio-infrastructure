import SwiftUI

@Observable
@MainActor
final class SponsorsViewModel {
    var sponsors: [Sponsor] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            let response: SponsorsResponse = try await APIClient.shared.request(.sponsors())
            sponsors = response.sponsors
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct SponsorsView: View {
    @State private var viewModel = SponsorsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sponsors.isEmpty {
                    ProgressView("Loading sponsors...")
                } else if viewModel.sponsors.isEmpty {
                    ContentUnavailableView(
                        "No Sponsors",
                        systemImage: "heart.fill",
                        description: Text("Organization sponsors will appear here.")
                    )
                } else {
                    List(viewModel.sponsors) { sponsor in
                        SponsorRow(sponsor: sponsor)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sponsors")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
        }
    }
}

struct SponsorRow: View {
    let sponsor: Sponsor

    var body: some View {
        HStack(spacing: 12) {
            if let logoUrl = sponsor.logo_url, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                } placeholder: {
                    sponsorIcon
                }
            } else {
                sponsorIcon
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sponsor.name)
                    .font(.subheadline.weight(.semibold))
                if let desc = sponsor.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let tier = sponsor.tier {
                StatusBadge(text: tier.capitalized, color: tierColor(tier))
            }
        }
        .padding(.vertical, 4)
    }

    private var sponsorIcon: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.secondarySystemBackground))
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.tertiary)
            }
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "platinum": return .purple
        case "gold": return .yellow
        case "silver": return .gray
        default: return .blue
        }
    }
}

#Preview {
    SponsorsView()
}
