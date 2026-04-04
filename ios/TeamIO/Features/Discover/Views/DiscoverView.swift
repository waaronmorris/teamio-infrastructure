import SwiftUI
import MapKit

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var locationService = LocationService()
    @State private var zipCode = ""
    @State private var showMap = false
    @State private var hasSearched = false
    @State private var selectedOrg: DiscoverOrg?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search header
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search by name...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .onSubmit { performSearch() }
                    }
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(
                                title: "Distance: \(viewModel.radiusMiles) mi",
                                systemImage: "location.circle"
                            )

                            Menu {
                                Button("All sports") { viewModel.selectedSport = nil; performSearch() }
                                ForEach(["Soccer", "Baseball", "Basketball", "Football", "Softball"], id: \.self) { sport in
                                    Button(sport) { viewModel.selectedSport = sport; performSearch() }
                                }
                            } label: {
                                FilterPill(
                                    title: viewModel.selectedSport ?? "All sports",
                                    systemImage: "sportscourt"
                                )
                            }

                            // View toggle
                            Button {
                                showMap.toggle()
                            } label: {
                                FilterPill(
                                    title: showMap ? "List" : "Map",
                                    systemImage: showMap ? "list.bullet" : "map"
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // Content
                if !hasSearched && locationService.location == nil {
                    // Location prompt
                    locationPrompt
                } else if viewModel.isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if showMap {
                    mapView
                } else {
                    listView
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if locationService.location == nil {
                    locationService.requestPermission()
                }
            }
            .onChange(of: locationService.location) { _, newLoc in
                if let coord = newLoc, !hasSearched {
                    hasSearched = true
                    performSearch()
                }
            }
            .sheet(item: $selectedOrg) { org in
                DiscoverOrgDetailView(org: org)
            }
        }
    }

    // MARK: - Location Prompt

    private var locationPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "location.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Where are you located?")
                .font(.title3.bold())

            Text("Enter your zip code to find programs nearby")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                TextField("Zip code", text: $zipCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 120)

                Button("Search") {
                    Task {
                        if let geo = await viewModel.geocodeZip(zipCode) {
                            locationService.location = CLLocationCoordinate2D(
                                latitude: geo.latitude,
                                longitude: geo.longitude
                            )
                            hasSearched = true
                            performSearch()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(zipCode.count != 5)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("\(viewModel.total) programs found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if viewModel.organizations.isEmpty {
                    ContentUnavailableView(
                        "No Programs Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try expanding your search radius or changing filters.")
                    )
                } else {
                    ForEach(viewModel.organizations) { org in
                        OrgCardView(org: org)
                            .onTapGesture { selectedOrg = org }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map {
            if let loc = locationService.location {
                Annotation("You", coordinate: loc) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            ForEach(viewModel.organizations) { org in
                if let lat = Double(org.city ?? ""), let lng = Double(org.state ?? "") {
                    // Organizations don't expose lat/lng publicly for privacy
                    // Pins would need a separate coordinate field in the response
                } else {
                    // Placeholder - map pins based on distance approximation
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .overlay(alignment: .bottom) {
            // Bottom sheet with org list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.organizations) { org in
                        OrgCardView(org: org, compact: true)
                            .frame(width: 280)
                            .onTapGesture { selectedOrg = org }
                    }
                }
                .padding()
            }
            .background(.thinMaterial)
        }
    }

    // MARK: - Helpers

    private func performSearch() {
        guard let loc = locationService.location else { return }
        Task {
            await viewModel.search(latitude: loc.latitude, longitude: loc.longitude)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }
}
