//
//  MainContentView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI
import Combine


struct MainContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reportStore: ReportStore
    @State private var unreadNotificationCount = 0
    @State private var showingQuickExit = true
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {

            NavigationView {
                HomeView()
                    .navigationTitle("SafeVoice")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.showingNotifications = true
                    }) {
                        Image(systemName: unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
                            .foregroundColor(unreadNotificationCount > 0 ? .red : .primary)
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            .sheet(isPresented: $appState.showingNotifications) {
                NavigationView {
                    NotificationCenterView(reportStore: reportStore)
                }
            }
            

            NavigationView {
                ReportCreationView()
            }
            .tabItem {
                Label("Report", systemImage: "exclamationmark.bubble.fill")
            }
            .tag(1)
            

            NavigationView {
                ResourcesView()
            }
            .tabItem {
                Label("Resources", systemImage: "hand.raised.fill")
            }
            .tag(2)
            

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .overlay(

            Group {
                if showingQuickExit {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                appState.activateEmergencyMode()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
            }
        )
        .onAppear {

            updateNotificationCount()
            

            if let user = appState.currentUser {
                showingQuickExit = user.preferences.emergencyOptions.enableEmergencyTap
            } else {
                showingQuickExit = true
            }
        }
    }
    

    private func updateNotificationCount() {
        unreadNotificationCount = notificationManager.pendingNotifications.count
    }
}
