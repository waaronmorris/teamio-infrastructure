import SwiftUI
import MapKit

@Observable
@MainActor
final class FieldsViewModel {
    var fields: [Field] = []
    var isLoading = false
    var error: String?
    var searchText = ""

    var filteredFields: [Field] {
        if searchText.isEmpty { return fields }
        return fields.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func load() async {
        isLoading = true
        do {
            let response: FieldsResponse = try await APIClient.shared.request(.fields())
            fields = response.fields
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct FieldsView: View {
    @State private var viewModel = FieldsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.fields.isEmpty {
                    ProgressView("Loading fields...")
                } else if viewModel.filteredFields.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    List(viewModel.filteredFields) { field in
                        NavigationLink {
                            FieldDetailView(field: field)
                        } label: {
                            FieldRow(field: field)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Fields")
            .searchable(text: $viewModel.searchText, prompt: "Search fields")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
        }
    }
}

struct FieldRow: View {
    let field: Field

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sportscourt")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(field.name)
                    .font(.subheadline.weight(.semibold))
                if let location = field.locationDisplay {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let type = field.field_type {
                        Text(type.capitalized)
                    }
                    if let surface = field.surface_type {
                        Text(surface.capitalized)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            if field.has_lights == true {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

struct FieldDetailView: View {
    let field: Field

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                // Map
                if let lat = field.latitude, let lon = field.longitude {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))) {
                        Marker(field.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
                }

                // Info
                VStack(alignment: .leading, spacing: 12) {
                    if let location = field.locationDisplay {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)

                        if let lat = field.latitude, let lon = field.longitude {
                            Button {
                                let mapItem = MKMapItem(placemark: MKPlacemark(
                                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                ))
                                mapItem.name = field.name
                                mapItem.openInMaps(launchOptions: [
                                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                ])
                            } label: {
                                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            }
                            .font(.subheadline)
                        }
                    }

                    Divider()

                    if let type = field.field_type {
                        HStack {
                            Text("Field Type")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(type.capitalized)
                        }
                        .font(.subheadline)
                    }

                    if let surface = field.surface_type {
                        HStack {
                            Text("Surface")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(surface.capitalized)
                        }
                        .font(.subheadline)
                    }
                }
                .cardStyle()

                // Amenities
                if !field.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(field.amenities, id: \.self) { amenity in
                                Label(amenity, systemImage: amenityIcon(amenity))
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .navigationTitle(field.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func amenityIcon(_ amenity: String) -> String {
        switch amenity {
        case "Lights": return "lightbulb.fill"
        case "Restrooms": return "toilet.fill"
        case "Parking": return "car.fill"
        default: return "checkmark.circle"
        }
    }
}

#Preview {
    FieldsView()
}
