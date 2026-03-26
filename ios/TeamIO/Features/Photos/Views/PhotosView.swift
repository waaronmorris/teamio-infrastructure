import SwiftUI

struct Photo: Decodable, Identifiable, Sendable {
    let id: String
    let url: String
    let thumbnail_url: String?
    let title: String?
    let album_type: String?
    let file_size: Int?
    let created_at: Date?
}

@Observable
@MainActor
final class PhotosViewModel {
    var photos: [Photo] = []
    var isLoading = false
    var error: String?
    var selectedAlbum: String = "all"
    var selectedPhoto: Photo?

    let albumTypes = ["all", "general", "team", "game", "practice", "event", "season"]

    func load() async {
        isLoading = true
        do {
            var queryItems: [URLQueryItem] = [URLQueryItem(name: "per_page", value: "48")]
            if selectedAlbum != "all" {
                queryItems.append(URLQueryItem(name: "album_type", value: selectedAlbum))
            }
            let response: PhotosResponse = try await APIClient.shared.request(.photos(), queryItems: queryItems)
            photos = response.photos
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct PhotosView: View {
    @State private var viewModel = PhotosViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Album filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.albumTypes, id: \.self) { album in
                            Button {
                                viewModel.selectedAlbum = album
                                Task { await viewModel.load() }
                            } label: {
                                Text(album.capitalized)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedAlbum == album
                                            ? Color.accentColor
                                            : Color(.secondarySystemBackground)
                                    )
                                    .foregroundStyle(
                                        viewModel.selectedAlbum == album ? .white : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }

                if viewModel.isLoading && viewModel.photos.isEmpty {
                    Spacer()
                    ProgressView("Loading photos...")
                    Spacer()
                } else if viewModel.photos.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Photos",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Photos will appear here once uploaded.")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(viewModel.photos) { photo in
                                Button {
                                    viewModel.selectedPhoto = photo
                                } label: {
                                    PhotoThumbnail(photo: photo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Photos")
            .sheet(item: $viewModel.selectedPhoto) { photo in
                PhotoDetailSheet(photo: photo)
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

struct PhotoThumbnail: View {
    let photo: Photo

    var body: some View {
        AsyncImage(url: URL(string: photo.thumbnail_url ?? photo.url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(1, contentMode: .fill)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            case .empty:
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(1, contentMode: .fill)
                    .overlay { ProgressView() }
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct PhotoDetailSheet: View {
    let photo: Photo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: photo.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        ContentUnavailableView("Failed to load", systemImage: "photo")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxHeight: .infinity)

                VStack(spacing: 8) {
                    if let title = photo.title {
                        Text(title)
                            .font(.headline)
                    }
                    HStack(spacing: 16) {
                        if let album = photo.album_type {
                            StatusBadge(text: album.capitalized, color: Color.accentColor)
                        }
                        Text(photo.created_at?.shortDate ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let size = photo.file_size {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PhotosView()
}
