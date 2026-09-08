import AppKit
import NotchHubCore
import SwiftUI

@MainActor
struct ShelfView: View {
    @ObservedObject private var store: ShelfStore
    @State private var unavailableItemIDs: Set<UUID> = []

    private let topInset: CGFloat
    private let onHome: () -> Void

    init(
        store: ShelfStore,
        topInset: CGFloat,
        onHome: @escaping () -> Void
    ) {
        self.store = store
        self.topInset = topInset
        self.onHome = onHome
    }

    var body: some View {
        VStack(spacing: 14) {
            header

            if store.items.isEmpty {
                emptyDropZone
            } else {
                itemList
            }

            if store.hasPersistenceError {
                Text("Shelf could not be saved. Existing files were not modified.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("shelf.persistenceError")
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .padding(.top, topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shelf.surface")
        .dropDestination(for: URL.self) { urls, _ in
            addDroppedURLs(urls)
        }
        .task {
            await store.loadIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onHome) {
                Label("Home", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.82))
            .accessibilityIdentifier("shelf.home")

            Spacer()

            Text("Shelf")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Button(action: presentOpenPanel) {
                Label("Add Files…", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.9))
            .accessibilityIdentifier("shelf.addFiles")
        }
    }

    private var emptyDropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.down")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.72))

            Text("Drop files or folders here")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Text("NotchHub stores only a read-only reference. The original stays where it is.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            .white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .accessibilityIdentifier("shelf.emptyDropZone")
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(store.items) { item in
                    itemRow(item)
                }
            }
        }
    }

    private func itemRow(_ item: ShelfItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .frame(width: 20)
                .foregroundStyle(.white.opacity(0.72))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if unavailableItemIDs.contains(item.id) {
                    Text("Unavailable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button {
                Task { await open(item) }
            } label: {
                Image(systemName: "arrow.up.forward.app")
            }
            .buttonStyle(.plain)
            .help("Open")
            .accessibilityLabel("Open \(item.displayName)")
            .accessibilityIdentifier("shelf.item.\(item.id.uuidString).open")

            Button {
                Task { await reveal(item) }
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.plain)
            .help("Show in Finder")
            .accessibilityLabel("Show \(item.displayName) in Finder")
            .accessibilityIdentifier("shelf.item.\(item.id.uuidString).reveal")

            Button(role: .destructive) {
                Task {
                    unavailableItemIDs.remove(item.id)
                    await store.remove(id: item.id)
                }
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .help("Remove from Shelf")
            .accessibilityLabel("Remove \(item.displayName) from Shelf")
            .accessibilityIdentifier("shelf.item.\(item.id.uuidString).remove")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            .white.opacity(0.065),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.resolvesAliases = true

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else {
            return
        }

        let urls = panel.urls.filter(\.isFileURL)
        guard !urls.isEmpty else {
            return
        }

        Task {
            await store.add(urls: urls)
        }
    }

    private func addDroppedURLs(_ urls: [URL]) -> Bool {
        let fileURLs = urls.filter(\.isFileURL)
        guard !fileURLs.isEmpty else {
            return false
        }

        Task {
            await store.add(urls: fileURLs)
        }
        return true
    }

    private func open(_ item: ShelfItem) async {
        guard let resolution = await store.resolve(item) else {
            unavailableItemIDs.insert(item.id)
            return
        }

        guard
            withSecurityScopedAccess(
                to: resolution.url,
                operation: { url in
                    _ = NSWorkspace.shared.open(url)
                })
        else {
            unavailableItemIDs.insert(item.id)
            return
        }
        unavailableItemIDs.remove(item.id)
    }

    private func reveal(_ item: ShelfItem) async {
        guard let resolution = await store.resolve(item) else {
            unavailableItemIDs.insert(item.id)
            return
        }

        guard
            withSecurityScopedAccess(
                to: resolution.url,
                operation: { url in
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                })
        else {
            unavailableItemIDs.insert(item.id)
            return
        }
        unavailableItemIDs.remove(item.id)
    }

    private func withSecurityScopedAccess(
        to url: URL,
        operation: (URL) -> Void
    ) -> Bool {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        guard didStartAccess else {
            return false
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        operation(url)
        return true
    }
}
