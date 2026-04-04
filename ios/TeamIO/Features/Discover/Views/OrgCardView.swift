import SwiftUI

struct OrgCardView: View {
    let org: DiscoverOrg
    var compact: Bool = false

    private let orgTypeLabels: [String: String] = [
        "parks_rec": "Parks & Rec",
        "league_org": "League",
        "travel_team": "Travel/Club",
        "tournament_org": "Tournament",
        "club": "Club",
        "school": "School",
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: compact ? 40 : 48, height: compact ? 40 : 48)

                if let url = org.logo_url, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.accent)
                    }
                    .frame(width: compact ? 40 : 48, height: compact ? 40 : 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.accent)
                        .font(compact ? .body : .title3)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name + verified
                HStack(spacing: 4) {
                    Text(org.name)
                        .font(compact ? .subheadline.bold() : .headline)
                        .lineLimit(1)

                    if org.is_verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
                }

                // Location + distance
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text("\(org.locationDisplay)\(org.distance_miles > 0 ? " \u{2022} \(String(format: "%.1f", org.distance_miles)) mi" : "")")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if !compact {
                    // Badges
                    HStack(spacing: 6) {
                        if let sport = org.sport {
                            TagView(text: sport, style: .accent)
                        }
                        TagView(
                            text: orgTypeLabels[org.org_type] ?? org.org_type,
                            style: .secondary
                        )
                        if org.open_season_count > 0 {
                            TagView(text: "Open Registration", style: .green)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(compact ? 10 : 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tag View

enum TagStyle {
    case accent, secondary, green
}

struct TagView: View {
    let text: String
    let style: TagStyle

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch style {
        case .accent: Color.accentColor.opacity(0.15)
        case .secondary: Color.secondary.opacity(0.1)
        case .green: Color.green.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .accent: .accentColor
        case .secondary: .secondary
        case .green: .green
        }
    }
}
