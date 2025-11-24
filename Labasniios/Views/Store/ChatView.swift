import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    @State private var selectedConversation: ChatConversationResponse?
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // 🔍 Filter conversations by search (first name AND last name)
    private var filteredConversations: [ChatConversationResponse] {
        guard !searchText.isEmpty else {
            return viewModel.conversations
        }
        
        let currentUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        
        // Normalize search text (no accents, lowercase)
        let normalizedSearch = searchText
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
        
        return viewModel.conversations.filter { conversation in
            // Get conversation partner
            let partner = conversation.participants.first { $0.id != currentUserId }
                       ?? conversation.participants.first!
            
            // Normalize full name
            let normalizedFullName = partner.fullName
                .folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
            
            // Check if full name contains the search text
            if normalizedFullName.contains(normalizedSearch) {
                return true
            }
            
            // Split full name (first name, last name...)
            let nameComponents = partner.fullName
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            // Check each component
            for component in nameComponents {
                let normalizedComponent = component
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .lowercased()
                
                if normalizedComponent.hasPrefix(normalizedSearch) ||
                   normalizedComponent.contains(normalizedSearch) {
                    return true
                }
            }
            
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFocused ? .themePrimary : .gray.opacity(0.6))
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.leading, 16)
                    
                    TextField("Search conversation...", text: $searchText)
                        .font(.subheadline)
                        .foregroundColor(.themePrimary)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    // Clear button
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 16))
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.themeAqua.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSearchFocused ? Color.themePrimary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
                .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                
                // MARK: - Conversations List
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredConversations) { conversation in
                                conversationRow(for: conversation)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(.themePrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .task {
                await viewModel.loadConversations()
            }
            .fullScreenCover(item: $selectedConversation) { conv in
                ChatDetailView(conversation: conv)
            }
            .onChange(of: selectedConversation) { newValue in
                if newValue == nil {
                    Task { await viewModel.loadConversations(showLoader: false) }
                }
            }
            // Hide keyboard on tap
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "message" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "No conversations yet" : "No results for '\(searchText)'")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Text("Clear search")
                        .font(.subheadline.bold())
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.themePrimary, lineWidth: 2)
                        )
                }
                .padding(.top, 8)
            }
        }
        .padding()
        Spacer()
    }
    
    // MARK: - Conversation Row
    @ViewBuilder
    private func conversationRow(for conversation: ChatConversationResponse) -> some View {
        let currentUserId = JWTDecoder.extractUserId(from: TokenManager.shared.getToken() ?? "")
        let partner = conversation.participants.first { $0.id != currentUserId }
                   ?? conversation.participants.first!
        
        let lastMsg = conversation.messages.last
        
        ChatRow(
            name: partner.fullName,
            message: lastMsg?.content ?? "Start the conversation",
            time: lastMsg?.createdAt.relativeTime() ?? "New",
            badge: nil,
            isOnline: false,
            profilePictureURL: partner.profilePicture,
            searchText: searchText
        )
        .onTapGesture {
            isSearchFocused = false
            selectedConversation = conversation
        }
    }
}

// MARK: - Relative Date
extension Date {
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "en_US")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - ChatRow.swift
struct ChatRow: View {
    let name: String
    let message: String
    let time: String
    let badge: Int?
    let isOnline: Bool
    let profilePictureURL: String?
    var searchText: String = ""
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let urlString = profilePictureURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(name.prefix(1))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(name.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                }
                
                // Online indicator
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.themeBackground, lineWidth: 3))
                }
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.themePrimary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time + badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let badge = badge {
                    Text("\(badge)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.themePrimary)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
}
