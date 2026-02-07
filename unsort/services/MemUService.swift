import Foundation

class MemUService {
    static let shared = MemUService()
    private let baseURL = URL(string: "https://api.memu.so/api/v3")!

    private let token = "mu_5TjIc9Ox_ksY__zIm1hOizVf0Rw6mZ7vR6lzve3Gt4UIDe7QC1XgsGH-fQlppgQthDdCTb_cQfj-D2KjGaN0VmvdPDSmf8nBC-L8CQ"
    private let userID = "unsort_user_001"
    private let agentID = "unsort_agent_001"
    
    private init() {}

    func memorize(text: String, contextTexts: [String]) async throws -> String {
        var conversation: [MemUConversationItem] = []

        if let context = contextTexts.last, !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            conversation.append(MemUConversationItem(role: "user", content: context))
            conversation.append(MemUConversationItem(role: "assistant", content: "了解しました。続けてください。"))
            conversation.append(MemUConversationItem(role: "user", content: text))
        } else {
            conversation.append(MemUConversationItem(role: "user", content: text))
            conversation.append(MemUConversationItem(role: "assistant", content: "記録しました。"))
            conversation.append(MemUConversationItem(role: "user", content: "以上"))
        }
        
        let body = MemUMemorizeRequest(
            conversation: conversation,
            user_id: userID,
            agent_id: agentID
        )
        
        let response: MemUMemorizeResponse = try await post(path: "/memory/memorize", body: body)
        return response.task_id
    }

    func checkTaskStatus(taskID: String) async throws -> Bool {
        let url = baseURL.appendingPathComponent("/memory/memorize/status/\(taskID)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let statusResponse = try JSONDecoder().decode(MemUTaskStatusResponse.self, from: data)
        
        if statusResponse.status == "SUCCESS" {
            return true
        } else if statusResponse.status == "FAILED" {
            throw NSError(domain: "MemUError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Task failed"])
        }
        
        return false // PENDING or PROCESSING
    }

    func fetchCategories() async throws -> [MemUCategory] {
        let body = MemUCategoriesRequest(
            user_id: userID,
            agent_id: agentID
        )
        
        let response: MemUCategoriesResponse = try await post(path: "/memory/categories", body: body)
        return response.categories
    }

    func retrieve(query: String) async throws -> MemURetrieveResponse {
        let body = MemURetrieveRequest(user_id: userID, agent_id: agentID, query: query)
        let response: MemURetrieveResponse = try await post(path: "/memory/retrieve", body: body)
        return response
    }
    
    private func post<T: Encodable, U: Decodable>(path: String, body: T) async throws -> U {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(U.self, from: data)
    }
}
