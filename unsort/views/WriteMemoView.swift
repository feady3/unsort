import SwiftUI

struct WriteMemoView: View {
    @State private var text: String = ""
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    @State private var errorMessage: String?
    
    @ObservedObject var localStore = LocalStorageService.shared
    let memUService = MemUService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Write Memo")
                    .font(.headline)
                Spacer()
                if isProcessing {
                    ProgressView()
                } else {
                    Button(action: sendMessage) {
                        Text("Send")
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(text.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .disabled(text.isEmpty)
                }
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // Input Area
            TextEditor(text: $text)
                .font(.body)
                .padding()
                .focused($isFocused)
                .frame(maxHeight: .infinity)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func sendMessage() {
        guard !text.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        let input = text
        
        Task {
            do {
                let raw = RawMemo(id: UUID(), text: input, date: Date())
                let contextTexts = localStore.recentRawMemoTexts(limit: 1)
                localStore.saveRawMemo(raw)
                
                let taskID = try await memUService.memorize(text: input, contextTexts: contextTexts)
                
                var attempts = 0
                while attempts < 10 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    if try await memUService.checkTaskStatus(taskID: taskID) {
                        break
                    }
                    attempts += 1
                }
                
                await localStore.syncWithMemU()
                
                await MainActor.run {
                    text = ""
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send memo: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}
