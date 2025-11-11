//
//  MainTabView.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: Tab = .dressing
    let user: User?
    let onLogout: (() -> Void)?
    
    enum Tab: String {
        case dressing = "Dressing"
        case tenues = "Tenues"
        case avatar = "Avatar"
        case store = "Store"
        case profil = "Profil"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Contenu principal
            Group {
                switch selectedTab {
                case .dressing:
                    DressingView()
                case .tenues:
                    TenuesView()
                case .avatar:
                    // Placeholder pour Avatar (statique pour le moment)
                    ZStack {
                        Color.themeBackground.ignoresSafeArea()
                        Text("Avatar")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.themeTeal)
                    }
                case .store:
                    StoreView()
                case .profil:
                    SettingsView(user: user, onLogout: {
                        performLogout()
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom bar personnalisé
            customBottomBar
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var customBottomBar: some View {
        VStack(spacing: 0) {
            // Ligne de séparation
            Rectangle()
                .fill(Color.themeSoftPink.opacity(0.3))
                .frame(height: 1)
            
            HStack(spacing: 0) {
                // Dressing
                tabButton(
                    icon: selectedTab == .dressing ? "tshirt.fill" : "tshirt",
                    label: "Dressing",
                    isSelected: selectedTab == .dressing,
                    action: { selectedTab = .dressing }
                )
                
                Spacer()
                
                // Tenues
                tabButton(
                    icon: selectedTab == .tenues ? "person.2.fill" : "person.2",
                    label: "Tenues",
                    isSelected: selectedTab == .tenues,
                    action: { selectedTab = .tenues }
                )
                
                Spacer()
                
                // Bouton central Avatar (plus grand et distinctif)
                Button {
                    selectedTab = .avatar
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.themePrimary)
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: selectedTab == .avatar ? "sparkles" : "sparkles")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -20)
                .accessibilityIdentifier("avatar-button")
                
                Spacer()
                
                // Store
                tabButton(
                    icon: selectedTab == .store ? "bag.fill" : "bag",
                    label: "Store",
                    isSelected: selectedTab == .store,
                    action: { selectedTab = .store }
                )
                
                Spacer()
                
                // Settings
                tabButton(
                    icon: selectedTab == .profil ? "person.crop.circle.fill" : "person.crop.circle",
                    label: "Settings",
                    isSelected: selectedTab == .profil,
                    action: { selectedTab = .profil }
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .padding(.bottom, 8)
            .background(
                Color.themeCard
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
            )
        }
    }
    
    private func tabButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .themePrimary : .themeSecondaryText)
                
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .themePrimary : .themeSecondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func performLogout() {
        // Appeler le callback de déconnexion qui va mettre navigateToProfile à false
        onLogout?()
    }
}

// MARK: - Previews
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(user: nil, onLogout: nil)
    }
}

