import Foundation
import Combine

class LocalStorageService: ObservableObject {
    static let shared = LocalStorageService()
    
    @Published var clusters: [Cluster] = []
    @Published var processedMemos: [ProcessedMemo] = []
    @Published var manualCategories: [ManualCategory] = []
    @Published private(set) var preferences = Preferences()
    
    private let fileManager = FileManager.default
    private let clustersFile = "clusters.json"
    private let memosFile = "processed_memos.json"
    private let rawMemosFile = "raw_memos.json"
    private let manualCategoriesFile = "manual_categories.json"
    private let preferencesFile = "preferences.json"
    
    private init() {
        loadData()
    }
    
    private func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func loadData() {
        self.clusters = load(fileName: clustersFile, type: [Cluster].self) ?? []
        self.processedMemos = load(fileName: memosFile, type: [ProcessedMemo].self) ?? []
        self.manualCategories = load(fileName: manualCategoriesFile, type: [ManualCategory].self) ?? []
        self.preferences = load(fileName: preferencesFile, type: Preferences.self) ?? Preferences()
    }
    
    private func load<T: Decodable>(fileName: String, type: T.Type) -> T? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Encodable>(data: T, fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: url)
        }
    }

    func loadRawMemos() -> [RawMemo] {
        (load(fileName: rawMemosFile, type: [RawMemo].self) ?? [])
            .filter { !$0.isDeleted }
            .sorted { $0.date > $1.date }
    }

    private func loadAllRawMemos() -> [RawMemo] {
        load(fileName: rawMemosFile, type: [RawMemo].self) ?? []
    }
    
    func saveRawMemo(_ memo: RawMemo) {
        var raws: [RawMemo] = loadAllRawMemos()
        raws.append(memo)
        save(data: raws, fileName: rawMemosFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func recentRawMemoTexts(limit: Int) -> [String] {
        let raws: [RawMemo] = loadRawMemos()
        guard limit > 0 else { return [] }
        return raws.suffix(limit).map { $0.text }
    }

    func isEntityCluster(_ cluster: Cluster) -> Bool {
        cluster.id.hasPrefix("entity:")
    }

    func isLocalCategoryCluster(_ cluster: Cluster) -> Bool {
        cluster.id.hasPrefix("local:")
    }

    func isManualCategoryCluster(_ cluster: Cluster) -> Bool {
        cluster.id.hasPrefix("manual:")
    }

    func isMemUCategoryCluster(_ cluster: Cluster) -> Bool {
        cluster.id.hasPrefix("memu:")
    }

    func sectionKey(for cluster: Cluster) -> String {
        if isEntityCluster(cluster) { return "people" }
        if isLocalCategoryCluster(cluster) { return "local" }
        if isManualCategoryCluster(cluster) { return "manual" }
        if isMemUCategoryCluster(cluster) { return "memu" }
        return "other"
    }

    func isClusterHidden(_ cluster: Cluster) -> Bool {
        Set(preferences.hiddenClusterIDs).contains(cluster.id)
    }

    func visibleOrderedClusters(in sectionKey: String, from clusters: [Cluster]) -> [Cluster] {
        let visible = clusters.filter { cluster in
            self.sectionKey(for: cluster) == sectionKey && !isClusterHidden(cluster)
        }

        let order = preferences.clusterOrderBySection[sectionKey] ?? []
        let indexMap = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })

        return visible.sorted { a, b in
            let ia = indexMap[a.id]
            let ib = indexMap[b.id]
            if let ia, let ib { return ia < ib }
            if ia != nil { return true }
            if ib != nil { return false }
            return a.name < b.name
        }
    }

    @MainActor
    func hideCluster(_ clusterID: String) {
        var hidden = Set(preferences.hiddenClusterIDs)
        hidden.insert(clusterID)
        preferences.hiddenClusterIDs = Array(hidden)
        save(data: preferences, fileName: preferencesFile)
        clusters.removeAll { $0.id == clusterID }
    }

    @MainActor
    func moveClusters(in sectionKey: String, from offsets: IndexSet, to destination: Int, current: [Cluster]) {
        var list = current
        applyMove(&list, from: offsets, to: destination)
        preferences.clusterOrderBySection[sectionKey] = list.map { $0.id }
        save(data: preferences, fileName: preferencesFile)
        clusters = recomputeClustersWithCurrentPreferences(from: clusters)
    }

    func rawMemos(for cluster: Cluster) -> [RawMemo] {
        if isEntityCluster(cluster) {
            return loadRawMemos()
                .filter { $0.text.contains(cluster.name) }
                .sorted { $0.date > $1.date }
        }
        if isLocalCategoryCluster(cluster) {
            return loadRawMemos()
                .filter { classifyLocalCategoryIDs(text: $0.text).contains(cluster.id) }
                .sorted { $0.date > $1.date }
        }
        if isManualCategoryCluster(cluster) {
            let categoryID = manualCategoryID(from: cluster)
            return loadRawMemos()
                .filter { $0.manualCategoryIDs.contains(categoryID) }
                .sorted { $0.date > $1.date }
        }
        return []
    }

    func rawMemoSummaries(for cluster: Cluster, limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        return rawMemos(for: cluster)
            .prefix(limit)
            .map { summarize(text: $0.text) }
    }

    func rawMemoCount(for cluster: Cluster) -> Int? {
        if isEntityCluster(cluster) || isLocalCategoryCluster(cluster) || isManualCategoryCluster(cluster) {
            return rawMemos(for: cluster).count
        }
        return nil
    }

    func syncWithMemU() async {
        let raws = loadRawMemos()

        let entityNames = extractEntityNames(from: raws.map { $0.text }.joined(separator: "\n"))
        let entityClusters = entityNames.map { name in
            Cluster(
                id: "entity:\(name)",
                name: name,
                description: "人物",
                summary: nil
            )
        }

        let localCategoryClusters = buildLocalCategoryClusters(from: raws)
        let manualClusters = buildManualCategoryClusters(from: raws)

        var memuClusters: [Cluster] = []
        if let categories = try? await MemUService.shared.fetchCategories() {
            memuClusters = categories.map { category in
                Cluster(
                    id: "memu:\(category.name)",
                    name: category.name,
                    description: category.description,
                    summary: category.summary
                )
            }
        }

        var merged: [String: Cluster] = [:]
        for cluster in entityClusters + localCategoryClusters + manualClusters + memuClusters {
            merged[cluster.id] = cluster
        }

        let newClusters = recomputeClustersWithCurrentPreferences(from: Array(merged.values))

        await MainActor.run {
            self.clusters = newClusters
        }

        save(data: newClusters, fileName: clustersFile)
    }

    @MainActor
    func refreshLocalClustersKeepingMemU() async {
        let raws = loadRawMemos()

        let entityNames = extractEntityNames(from: raws.map { $0.text }.joined(separator: "\n"))
        let entityClusters = entityNames.map { name in
            Cluster(id: "entity:\(name)", name: name, description: "人物", summary: nil)
        }

        let localCategoryClusters = buildLocalCategoryClusters(from: raws)
        let manualClusters = buildManualCategoryClusters(from: raws)
        let memuClusters = clusters.filter { isMemUCategoryCluster($0) }

        var merged: [String: Cluster] = [:]
        for cluster in entityClusters + localCategoryClusters + manualClusters + memuClusters {
            merged[cluster.id] = cluster
        }

        let newClusters = recomputeClustersWithCurrentPreferences(from: Array(merged.values))
        clusters = newClusters
        save(data: newClusters, fileName: clustersFile)
    }
    
    func getMemos(for clusterID: String) -> [ProcessedMemo] {
        processedMemos.filter { $0.clusterID == clusterID }
    }

    func createManualCategory(name: String, description: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let category = ManualCategory(
            id: UUID().uuidString,
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        manualCategories.append(category)
        save(data: manualCategories, fileName: manualCategoriesFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func deleteManualCategory(id: String) {
        manualCategories.removeAll { $0.id == id }
        save(data: manualCategories, fileName: manualCategoriesFile)

        var raws = loadAllRawMemos()
        for i in raws.indices {
            raws[i].manualCategoryIDs.removeAll { $0 == id }
        }
        save(data: raws, fileName: rawMemosFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func updateRawMemo(id: UUID, newText: String) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var raws = loadAllRawMemos()
        guard let index = raws.firstIndex(where: { $0.id == id }) else { return }
        raws[index].text = trimmed
        save(data: raws, fileName: rawMemosFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func deleteRawMemo(id: UUID) {
        var raws = loadAllRawMemos()
        guard let index = raws.firstIndex(where: { $0.id == id }) else { return }
        raws[index].isDeleted = true
        save(data: raws, fileName: rawMemosFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func isMemo(_ memo: RawMemo, inManualCategoryID categoryID: String) -> Bool {
        memo.manualCategoryIDs.contains(categoryID)
    }

    func toggleMemo(_ memoID: UUID, manualCategoryID: String) {
        var raws = loadAllRawMemos()
        guard let index = raws.firstIndex(where: { $0.id == memoID }) else { return }
        if raws[index].manualCategoryIDs.contains(manualCategoryID) {
            raws[index].manualCategoryIDs.removeAll { $0 == manualCategoryID }
        } else {
            raws[index].manualCategoryIDs.append(manualCategoryID)
        }
        save(data: raws, fileName: rawMemosFile)
        Task { await refreshLocalClustersKeepingMemU() }
    }

    func applyMemUItemPreferences(clusterID: String, items: [AggregatedMemUItem]) -> [AggregatedMemUItem] {
        let prefs = preferences.memUItemPrefsByCluster[clusterID] ?? MemUItemPreferences()
        let hidden = Set(prefs.hiddenItemIDs)

        let visible = items.filter { !hidden.contains($0.id) }
        let order = prefs.order
        let indexMap = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })

        return visible.sorted { a, b in
            let ia = indexMap[a.id]
            let ib = indexMap[b.id]
            if let ia, let ib { return ia < ib }
            if ia != nil { return true }
            if ib != nil { return false }
            if a.count != b.count { return a.count > b.count }
            return a.content.count > b.content.count
        }
    }

    @MainActor
    func hideMemUItem(clusterID: String, itemID: String) {
        var prefs = preferences.memUItemPrefsByCluster[clusterID] ?? MemUItemPreferences()
        var hidden = Set(prefs.hiddenItemIDs)
        hidden.insert(itemID)
        prefs.hiddenItemIDs = Array(hidden)
        preferences.memUItemPrefsByCluster[clusterID] = prefs
        save(data: preferences, fileName: preferencesFile)
    }

    @MainActor
    func setMemUItemOrder(clusterID: String, orderedItemIDs: [String]) {
        var prefs = preferences.memUItemPrefsByCluster[clusterID] ?? MemUItemPreferences()
        prefs.order = orderedItemIDs
        preferences.memUItemPrefsByCluster[clusterID] = prefs
        save(data: preferences, fileName: preferencesFile)
    }

    private func extractEntityNames(from text: String) -> [String] {
        let pattern = "([一-龥]{1,10}さん)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let names = matches.map { nsText.substring(with: $0.range(at: 1)) }
        return Array(Set(names)).sorted()
    }

    private func summarize(text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.count <= 60 { return normalized }
        return String(normalized.prefix(60)) + "…"
    }

    private struct LocalCategoryDefinition {
        let id: String
        let name: String
        let description: String
        let keywords: [String]
    }

    private func localCategoryDefinitions() -> [LocalCategoryDefinition] {
        [
            LocalCategoryDefinition(
                id: "local:novel",
                name: "小説・創作",
                description: "構想・設定・プロット",
                keywords: ["小説", "物語", "プロット", "設定", "登場人物", "章", "シーン", "キャラ", "世界観", "構想"]
            ),
            LocalCategoryDefinition(
                id: "local:study",
                name: "勉強",
                description: "学習・読書・復習",
                keywords: ["勉強", "学習", "復習", "読書", "講義", "試験", "テスト", "暗記", "演習"]
            ),
            LocalCategoryDefinition(
                id: "local:work",
                name: "仕事",
                description: "会議・資料・業務",
                keywords: ["仕事", "会議", "ミーティング", "報告", "資料", "顧客", "取引先", "納期", "レビュー", "PM"]
            ),
            LocalCategoryDefinition(
                id: "local:plan",
                name: "計画・タスク",
                description: "予定・TODO・締切",
                keywords: ["計画", "予定", "タスク", "TODO", "ToDo", "やること", "締切", "期限", "リマインド", "明日", "今週", "来週", "今月"]
            ),
            LocalCategoryDefinition(
                id: "local:idea",
                name: "アイデア",
                description: "発想メモ",
                keywords: ["アイデア", "発想", "ひらめき", "案", "ネタ", "企画"]
            ),
            LocalCategoryDefinition(
                id: "local:misc",
                name: "その他",
                description: "未分類",
                keywords: []
            )
        ]
    }

    private func classifyLocalCategoryIDs(text: String) -> Set<String> {
        let normalized = text.lowercased()
        var matched: Set<String> = []

        for def in localCategoryDefinitions() where def.id != "local:misc" {
            if def.keywords.contains(where: { normalized.contains($0.lowercased()) }) {
                matched.insert(def.id)
            }
        }

        if matched.isEmpty {
            matched.insert("local:misc")
        }

        return matched
    }

    private func buildLocalCategoryClusters(from raws: [RawMemo]) -> [Cluster] {
        let defs = localCategoryDefinitions()
        var counts: [String: Int] = [:]

        for raw in raws {
            for id in classifyLocalCategoryIDs(text: raw.text) {
                counts[id, default: 0] += 1
            }
        }

        return defs.compactMap { def in
            guard (counts[def.id] ?? 0) > 0 else { return nil }
            return Cluster(id: def.id, name: def.name, description: def.description, summary: nil)
        }
    }

    private func buildManualCategoryClusters(from raws: [RawMemo]) -> [Cluster] {
        let visible = manualCategories.sorted { $0.createdAt > $1.createdAt }
        return visible.map { category in
            Cluster(
                id: "manual:\(category.id)",
                name: category.name,
                description: category.description.isEmpty ? "手動カテゴリ" : category.description,
                summary: nil
            )
        }
    }

    private func manualCategoryID(from cluster: Cluster) -> String {
        String(cluster.id.dropFirst("manual:".count))
    }

    private func recomputeClustersWithCurrentPreferences(from clusters: [Cluster]) -> [Cluster] {
        let hidden = Set(preferences.hiddenClusterIDs)
        let visible = clusters.filter { !hidden.contains($0.id) }

        let sections = ["people", "local", "manual", "memu", "other"]
        var result: [Cluster] = []
        for section in sections {
            let sectionClusters = visible.filter { self.sectionKey(for: $0) == section }
            let order = preferences.clusterOrderBySection[section] ?? []
            let indexMap = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            let sorted = sectionClusters.sorted { a, b in
                let ia = indexMap[a.id]
                let ib = indexMap[b.id]
                if let ia, let ib { return ia < ib }
                if ia != nil { return true }
                if ib != nil { return false }
                return a.name < b.name
            }
            result.append(contentsOf: sorted)
        }
        return result
    }

    struct MemUItemPreferences: Codable {
        var hiddenItemIDs: [String] = []
        var order: [String] = []
    }

    struct Preferences: Codable {
        var hiddenClusterIDs: [String] = []
        var clusterOrderBySection: [String: [String]] = [:]
        var memUItemPrefsByCluster: [String: MemUItemPreferences] = [:]
    }

    private func applyMove<T>(_ array: inout [T], from offsets: IndexSet, to destination: Int) {
        let moving = offsets.sorted().map { array[$0] }
        for index in offsets.sorted(by: >) {
            array.remove(at: index)
        }
        let adjustedDestination = destination - offsets.filter { $0 < destination }.count
        array.insert(contentsOf: moving, at: max(0, min(adjustedDestination, array.count)))
    }
}
