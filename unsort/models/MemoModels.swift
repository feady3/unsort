import Foundation

// MARK: - Models

struct RawMemo: Codable, Identifiable {
    let id: UUID
    var text: String
    let date: Date
    var manualCategoryIDs: [String]
    var isDeleted: Bool

    init(id: UUID, text: String, date: Date, manualCategoryIDs: [String] = [], isDeleted: Bool = false) {
        self.id = id
        self.text = text
        self.date = date
        self.manualCategoryIDs = manualCategoryIDs
        self.isDeleted = isDeleted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case manualCategoryIDs
        case isDeleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        date = try container.decode(Date.self, forKey: .date)
        manualCategoryIDs = (try? container.decode([String].self, forKey: .manualCategoryIDs)) ?? []
        isDeleted = (try? container.decode(Bool.self, forKey: .isDeleted)) ?? false
    }
}

struct Cluster: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let summary: String? // Added to support MemU's category summary
}

struct ManualCategory: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    let createdAt: Date
}

struct ProcessedMemo: Codable, Identifiable {
    let id: UUID
    let originalMemoID: UUID
    let summary: String
    let topics: [String]
    let clusterID: String
    let date: Date
}

// MARK: - MemU API Models

struct MemUConversationItem: Codable {
    let role: String
    let content: String
}

struct MemUMemorizeRequest: Codable {
    let conversation: [MemUConversationItem]
    let user_id: String
    let agent_id: String
}

struct MemUMemorizeResponse: Codable {
    let task_id: String
    let status: String
    let message: String
}

struct MemUTaskStatusResponse: Codable {
    let task_id: String
    let status: String
}

struct MemUCategoriesRequest: Codable {
    let user_id: String
    let agent_id: String
}

struct MemUCategoriesResponse: Codable {
    let categories: [MemUCategory]
}

struct MemUCategory: Codable {
    let name: String
    let description: String
    let summary: String
    let user_id: String
    let agent_id: String
}

struct MemURetrieveRequest: Codable {
    let user_id: String
    let agent_id: String
    let query: String
}

struct MemURetrieveResponse: Codable {
    let rewritten_query: String?
    let categories: [MemURetrieveCategory]?
    let items: [MemURetrieveItem]?
}

struct MemURetrieveCategory: Codable {
    let name: String
    let description: String
    let summary: String
}

struct MemURetrieveItem: Codable, Identifiable {
    var id: String { memory_type + ":" + content }
    let memory_type: String
    let content: String
}

struct AggregatedMemUItem: Identifiable, Codable {
    let id: String
    let memoryType: String
    let content: String
    let count: Int
}
