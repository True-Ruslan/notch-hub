import NotchHubCore
import SwiftUI

@MainActor
struct SnippetsView: View {
    private enum EditorMode: Equatable {
        case add
        case edit(UUID)
    }

    @ObservedObject private var store: SnippetStore
    private let clipboardWriter: any SnippetClipboardWriting
    private let topInset: CGFloat
    private let onHome: () -> Void

    @State private var editorMode: EditorMode?
    @State private var draftText = ""
    @State private var pendingDeleteID: UUID?

    init(
        store: SnippetStore,
        clipboardWriter: any SnippetClipboardWriting,
        topInset: CGFloat,
        onHome: @escaping () -> Void
    ) {
        self.store = store
        self.clipboardWriter = clipboardWriter
        self.topInset = topInset
        self.onHome = onHome
    }

    var body: some View {
        Group {
            if editorMode != nil {
                editorContent
            } else {
                listContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("snippets.surface")
        .task {
            await store.loadIfNeeded()
        }
        .confirmationDialog(
            "Delete snippet?",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let id = pendingDeleteID else {
                    return
                }
                pendingDeleteID = nil
                Task {
                    await store.remove(id: id)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteID = nil
            }
        }
    }

    private var listContent: some View {
        VStack(spacing: 14) {
            header

            if store.hasPersistenceError {
                Text("Some snippet changes could not be persisted.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if store.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.badge.plus")
                        .font(.title2)
                    Text("No snippets yet")
                        .font(.headline)
                    Text("Add reusable text and copy it when needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(.white)
                .accessibilityIdentifier("snippets.empty")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.items) { item in
                            snippetRow(item)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, topInset)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onHome) {
                Label("Home", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("snippets.home")

            Text("Snippets")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Button {
                beginAdd()
            } label: {
                Label("Add", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("snippets.add")
        }
        .foregroundStyle(.white)
    }

    private func snippetRow(_ item: SnippetItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayTitle(for: item.text))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(item.text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(2)
                .textSelection(.disabled)

            HStack(spacing: 12) {
                Button("Copy") {
                    _ = clipboardWriter.write(item.text)
                }
                .accessibilityIdentifier("snippets.item.\(item.id.uuidString).copy")

                Button("Edit") {
                    beginEdit(item)
                }
                .accessibilityIdentifier("snippets.item.\(item.id.uuidString).edit")

                Button("Delete", role: .destructive) {
                    pendingDeleteID = item.id
                }
                .accessibilityIdentifier("snippets.item.\(item.id.uuidString).delete")
            }
            .buttonStyle(.plain)
            .font(.caption.weight(.medium))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var editorContent: some View {
        VStack(spacing: 14) {
            HStack {
                Text(editorTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            TextEditor(text: $draftText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    .white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .accessibilityIdentifier("snippets.editor.text")

            HStack {
                Button("Cancel") {
                    cancelEditor()
                }
                .accessibilityIdentifier("snippets.editor.cancel")

                Spacer()

                Button("Save") {
                    Task {
                        await saveDraft()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("snippets.editor.save")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, topInset)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("snippets.editor")
    }

    private var editorTitle: String {
        switch editorMode {
        case .add:
            "Add snippet"
        case .edit:
            "Edit snippet"
        case nil:
            "Snippet"
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteID = nil
                }
            }
        )
    }

    private func beginAdd() {
        editorMode = .add
        draftText = ""
    }

    private func beginEdit(_ item: SnippetItem) {
        editorMode = .edit(item.id)
        draftText = item.text
    }

    private func cancelEditor() {
        editorMode = nil
        draftText = ""
    }

    private func saveDraft() async {
        let didSave: Bool
        switch editorMode {
        case .add:
            didSave = await store.add(text: draftText)
        case let .edit(id):
            didSave = await store.update(id: id, text: draftText)
        case nil:
            return
        }

        if didSave {
            cancelEditor()
        }
    }

    private func displayTitle(for text: String) -> String {
        text.split(whereSeparator: \.isNewline)
            .map(String.init)
            .first(where: {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
            })?
            .prefix(60)
            .description ?? "Untitled snippet"
    }
}
