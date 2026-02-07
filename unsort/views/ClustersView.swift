import SwiftUI

struct ClustersView: View {
    @ObservedObject var localStore = LocalStorageService.shared
    @State private var isPresentingCreateCategory = false
    
    var body: some View {
        NavigationStack {
            List {
                if localStore.clusters.isEmpty {
                    ContentUnavailableView("No Memories Yet", systemImage: "brain", description: Text("Write some notes to see them organized here."))
                } else {
                    let peopleClusters = localStore.visibleOrderedClusters(in: "people", from: localStore.clusters)
                    let localClusters = localStore.visibleOrderedClusters(in: "local", from: localStore.clusters)
                    let manualClusters = localStore.visibleOrderedClusters(in: "manual", from: localStore.clusters)
                    let memuClusters = localStore.visibleOrderedClusters(in: "memu", from: localStore.clusters)
                    
                    if !peopleClusters.isEmpty {
                        Section("People") {
                            ForEach(peopleClusters) { cluster in
                                NavigationLink(destination: ClusterDetailView(cluster: cluster)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            Text(cluster.name)
                                                .font(.headline)
                                            Spacer()
                                            if let count = localStore.rawMemoCount(for: cluster) {
                                                Text("\(count)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.secondary.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        
                                        Text(cluster.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        let previews = localStore.rawMemoSummaries(for: cluster, limit: 2)
                                        if !previews.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                ForEach(Array(previews.enumerated()), id: \.offset) { _, preview in
                                                    Text(preview)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 8)
                                                        .background(Color.secondary.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .onMove { offsets, destination in
                                localStore.moveClusters(in: "people", from: offsets, to: destination, current: peopleClusters)
                            }
                            .onDelete { indexSet in
                                let targets = indexSet.map { peopleClusters[$0] }
                                for cluster in targets {
                                    localStore.hideCluster(cluster.id)
                                }
                            }
                        }
                    }
                    
                    if !localClusters.isEmpty {
                        Section("Local") {
                            ForEach(localClusters) { cluster in
                                NavigationLink(destination: ClusterDetailView(cluster: cluster)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            Text(cluster.name)
                                                .font(.headline)
                                            Spacer()
                                            if let count = localStore.rawMemoCount(for: cluster) {
                                                Text("\(count)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.secondary.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        
                                        Text(cluster.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        let previews = localStore.rawMemoSummaries(for: cluster, limit: 2)
                                        if !previews.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                ForEach(Array(previews.enumerated()), id: \.offset) { _, preview in
                                                    Text(preview)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 8)
                                                        .background(Color.secondary.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .onMove { offsets, destination in
                                localStore.moveClusters(in: "local", from: offsets, to: destination, current: localClusters)
                            }
                            .onDelete { indexSet in
                                let targets = indexSet.map { localClusters[$0] }
                                for cluster in targets {
                                    localStore.hideCluster(cluster.id)
                                }
                            }
                        }
                    }
                    
                    if !manualClusters.isEmpty {
                        Section("Manual") {
                            ForEach(manualClusters) { cluster in
                                NavigationLink(destination: ClusterDetailView(cluster: cluster)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            Text(cluster.name)
                                                .font(.headline)
                                            Spacer()
                                            if let count = localStore.rawMemoCount(for: cluster) {
                                                Text("\(count)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.secondary.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        
                                        Text(cluster.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        let previews = localStore.rawMemoSummaries(for: cluster, limit: 2)
                                        if !previews.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                ForEach(Array(previews.enumerated()), id: \.offset) { _, preview in
                                                    Text(preview)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 8)
                                                        .background(Color.secondary.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        let id = String(cluster.id.dropFirst("manual:".count))
                                        localStore.deleteManualCategory(id: id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onMove { offsets, destination in
                                localStore.moveClusters(in: "manual", from: offsets, to: destination, current: manualClusters)
                            }
                            .onDelete { indexSet in
                                let targets = indexSet.map { manualClusters[$0] }
                                for cluster in targets {
                                    let id = String(cluster.id.dropFirst("manual:".count))
                                    localStore.deleteManualCategory(id: id)
                                }
                            }
                        }
                    }

                    if !memuClusters.isEmpty {
                        Section("MemU") {
                            ForEach(memuClusters) { cluster in
                                NavigationLink(destination: ClusterDetailView(cluster: cluster)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(cluster.name)
                                            .font(.headline)

                                        Text(cluster.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let summary = cluster.summary {
                                            Text(snippet(from: summary))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .onMove { offsets, destination in
                                localStore.moveClusters(in: "memu", from: offsets, to: destination, current: memuClusters)
                            }
                            .onDelete { indexSet in
                                let targets = indexSet.map { memuClusters[$0] }
                                for cluster in targets {
                                    localStore.hideCluster(cluster.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCreateCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await localStore.syncWithMemU()
            }
            .task {
                await localStore.syncWithMemU()
            }
            .sheet(isPresented: $isPresentingCreateCategory) {
                CreateManualCategoryView()
            }
        }
    }
    
    private func snippet(from text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.count <= 120 { return normalized }
        return String(normalized.prefix(120)) + "…"
    }
}

struct ClusterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let cluster: Cluster
    @ObservedObject var localStore = LocalStorageService.shared
    @State private var items: [MemURetrieveItem] = []
    @State private var aggregatedItems: [AggregatedMemUItem] = []
    @State private var showRawItems: Bool = false
    @State private var isLoading: Bool = false
    @State private var retrievedSummary: String?
    @State private var localMemos: [RawMemo] = []
    @State private var isPresentingEditMemo = false
    @State private var editingMemoID: UUID?
    @State private var editingText: String = ""
    
    var body: some View {
        List {
            Section(header: Text("Description")) {
                Text(cluster.description)
                    .font(.body)
            }
            
            if let summary = cluster.summary, let attributed = try? AttributedString(markdown: summary) {
                Section(header: Text("Summary")) {
                    Text(attributed)
                        .font(.body)
                }
            } else if let summary = cluster.summary {
                Section(header: Text("Summary")) {
                    Text(summary)
                        .font(.body)
                }
            } else if let summary = retrievedSummary, let attributed = try? AttributedString(markdown: summary) {
                Section(header: Text("Summary")) {
                    Text(attributed)
                        .font(.body)
                }
            } else if let summary = retrievedSummary {
                Section(header: Text("Summary")) {
                    Text(summary)
                        .font(.body)
                }
            }

            Section(header: memUHeader) {
                if isLoading {
                    ProgressView()
                } else if (showRawItems ? items.isEmpty : aggregatedItems.isEmpty) {
                    Text("No memos found.")
                        .foregroundColor(.secondary)
                } else {
                    if showRawItems {
                        ForEach(items) { item in
                            Text(bulletLine(item.content))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        let id = memUItemID(memoryType: item.memory_type, content: item.content)
                                        localStore.hideMemUItem(clusterID: cluster.id, itemID: id)
                                        aggregatedItems = localStore.applyMemUItemPreferences(clusterID: cluster.id, items: aggregatedItems)
                                    } label: {
                                        Label("非表示", systemImage: "eye.slash")
                                    }
                                }
                        }
                    } else {
                        ForEach(aggregatedItems) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(bulletLine(item.content))
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                if item.count > 1 {
                                    Text("×\(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    localStore.hideMemUItem(clusterID: cluster.id, itemID: item.id)
                                    aggregatedItems.removeAll { $0.id == item.id }
                                } label: {
                                    Label("非表示", systemImage: "eye.slash")
                                }
                            }
                        }
                        .onMove { offsets, destination in
                            var moved = aggregatedItems
                            moved.move(fromOffsets: offsets, toOffset: destination)
                            aggregatedItems = moved
                            localStore.setMemUItemOrder(clusterID: cluster.id, orderedItemIDs: moved.map { $0.id })
                        }
                        .onDelete { indexSet in
                            let targets = indexSet.map { aggregatedItems[$0] }
                            for t in targets {
                                localStore.hideMemUItem(clusterID: cluster.id, itemID: t.id)
                            }
                            aggregatedItems.remove(atOffsets: indexSet)
                        }
                    }
                }
            }

            if !localMemos.isEmpty {
                Section(header: Text("Local Memos")) {
                    ForEach(localMemos) { memo in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(summarize(memo.text))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(memo.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                localStore.deleteRawMemo(id: memo.id)
                                localMemos = localStore.rawMemos(for: cluster)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingMemoID = memo.id
                                editingText = memo.text
                                isPresentingEditMemo = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            ForEach(localStore.manualCategories) { category in
                                Button {
                                    localStore.toggleMemo(memo.id, manualCategoryID: category.id)
                                    localMemos = localStore.rawMemos(for: cluster)
                                } label: {
                                    if memo.manualCategoryIDs.contains(category.id) {
                                        Label(category.name, systemImage: "checkmark")
                                    } else {
                                        Text(category.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(cluster.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            if localStore.isManualCategoryCluster(cluster) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        let id = String(cluster.id.dropFirst("manual:".count))
                        localStore.deleteManualCategory(id: id)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .refreshable {
            await load()
        }
        .task {
            await load()
        }
        .sheet(isPresented: $isPresentingEditMemo) {
            NavigationStack {
                Form {
                    Section {
                        TextEditor(text: $editingText)
                            .frame(minHeight: 180)
                    }
                }
                .navigationTitle("Edit Memo")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresentingEditMemo = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let id = editingMemoID {
                                localStore.updateRawMemo(id: id, newText: editingText)
                                localMemos = localStore.rawMemos(for: cluster)
                            }
                            isPresentingEditMemo = false
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        localMemos = localStore.rawMemos(for: cluster)

        do {
            let response = try await MemUService.shared.retrieve(query: japaneseBulletQuery(for: cluster))
            items = response.items ?? []
            aggregatedItems = localStore.applyMemUItemPreferences(clusterID: cluster.id, items: aggregateMemUItems(items))
            retrievedSummary = response.categories?.first?.summary
        } catch {
            items = []
            aggregatedItems = []
            retrievedSummary = nil
        }
    }

    private func summarize(_ text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.count <= 140 { return normalized }
        return String(normalized.prefix(140)) + "…"
    }

    private var memUHeader: some View {
        HStack {
            Text("MemU")
            Spacer()
            Button(showRawItems ? "Compact" : "Raw") {
                showRawItems.toggle()
            }
            .font(.caption)
        }
    }

    private func japaneseBulletQuery(for cluster: Cluster) -> String {
        let topic = cluster.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        日本語で回答してください。
        出力は箇条書き（各行の先頭に「・」）にしてください。
        内容が重複している場合は統合して、短く分かりやすくまとめてください。
        テーマ: \(topic)
        """
    }

    private func memUItemID(memoryType: String, content: String) -> String {
        memoryType + ":" + normalizeForDedup(content)
    }

    private func bulletLine(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let cleaned = trimmed
            .replacingOccurrences(of: "•", with: "・")
            .replacingOccurrences(of: "- ", with: "・")
            .replacingOccurrences(of: "The user ", with: "")
            .replacingOccurrences(of: "The user", with: "")
            .replacingOccurrences(of: "User ", with: "")
            .replacingOccurrences(of: "User", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("・") { return cleaned }
        return "・" + cleaned
    }

    private func aggregateMemUItems(_ items: [MemURetrieveItem]) -> [AggregatedMemUItem] {
        let cleaned = items
            .map { MemURetrieveItem(memory_type: $0.memory_type, content: $0.content.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.content.isEmpty }

        var result: [AggregatedMemUItem] = []
        var used = Array(repeating: false, count: cleaned.count)

        for i in cleaned.indices {
            if used[i] { continue }
            used[i] = true

            var group: [MemURetrieveItem] = [cleaned[i]]
            let a = normalizeForDedup(cleaned[i].content)

            for j in cleaned.indices where j > i {
                if used[j] { continue }
                if cleaned[i].memory_type != cleaned[j].memory_type { continue }
                let b = normalizeForDedup(cleaned[j].content)

                if a == b || isNearDuplicate(a: a, b: b) {
                    used[j] = true
                    group.append(cleaned[j])
                }
            }

            let representative = group
                .sorted { $0.content.count > $1.content.count }
                .first!

            result.append(
                AggregatedMemUItem(
                    id: representative.memory_type + ":" + normalizeForDedup(representative.content),
                    memoryType: representative.memory_type,
                    content: representative.content,
                    count: group.count
                )
            )
        }

        return result.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.content.count > rhs.content.count
        }
    }

    private func normalizeForDedup(_ text: String) -> String {
        let lowered = text.lowercased()
        let stripped = lowered
            .replacingOccurrences(of: "　", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        let collapsed = stripped
            .split(separator: " ")
            .joined(separator: " ")
        let removedPunct = collapsed
            .replacingOccurrences(of: "、", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "．", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "！", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "？", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return removedPunct
    }

    private func isNearDuplicate(a: String, b: String) -> Bool {
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }

        let shorter: String
        let longer: String
        if a.count <= b.count {
            shorter = a
            longer = b
        } else {
            shorter = b
            longer = a
        }

        if shorter.count >= 12, longer.contains(shorter) { return true }
        if shorter.count <= 10 { return false }

        let aSet = Set(a.map { String($0) })
        let bSet = Set(b.map { String($0) })
        let intersection = aSet.intersection(bSet).count
        let union = aSet.union(bSet).count
        guard union > 0 else { return false }
        let jaccard = Double(intersection) / Double(union)
        return jaccard >= 0.92
    }
}

struct CreateManualCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localStore = LocalStorageService.shared
    @State private var name: String = ""
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                }
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        localStore.createManualCategory(name: name, description: description)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
