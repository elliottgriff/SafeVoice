//
//  SafeVoiceApp.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI
import Combine

@main
struct SafeVoiceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var reportStore = ReportStore()
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(reportStore)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        appState.loadSavedUserState()
        
        if appState.currentUser == nil {
            let settings = UserDefaults.standard
            if settings.bool(forKey: "startInDisguiseMode") {
                appState.disguiseMode = true
            }
        }
        
        startUpdateChecks()
    }
    
    private func startUpdateChecks() {
        // Check for report updates every 10 minutes when app is running
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            reportStore.checkForUpdates()
            
            NotificationManager.shared.checkForReportNotifications(reports: reportStore.activeReports)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var disguiseMode = false
    @Published var currentUser: User?
    
    @Published var selectedTab = 0
    @Published var showingNewReport = false
    @Published var showingAllReports = false
    @Published var showingNotifications = false
    @Published var showingSettings = false
    @Published var showingProfile = false
    
    @Published var selectedReportID: String?
    @Published var selectedResourceID: String?
    
    @Published var isInEmergencyMode = false
    @Published var isInIncognitoMode = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func toggleDisguiseMode() {
        disguiseMode.toggle()
        
        if !disguiseMode {
            checkAuthentication()
        }
    }
    
    // Check authentication
    private func checkAuthentication() {
        let settings = UserDefaults.standard
        let securityEnabled = settings.bool(forKey: "securityEnabled")
        
        if securityEnabled && currentUser != nil {
            isAuthenticated = false
        }
    }
    
    func activateEmergencyMode() {
        isInEmergencyMode = true
        disguiseMode = true
        
        if isInIncognitoMode {
            clearSensitiveData()
        }
    }
    
    private func clearSensitiveData() {
        let shouldClearData = UserDefaults.standard.bool(forKey: "clearDataOnEmergency")
        if shouldClearData {
            // Would clear reports, history, etc.
        }
    }
    
    func resetAppState() {
        isAuthenticated = false
        disguiseMode = false
        currentUser = nil
        selectedTab = 0
        isInEmergencyMode = false
        isInIncognitoMode = false
    }
}

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reportStore: ReportStore
    @State private var showingAuth = false
    @State private var showingWelcomeBack = false
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var backgroundCheckTimer: Timer?
    
    var body: some View {
        Group {
            if appState.disguiseMode {
                DisguiseRouter()
            } else if !appState.isAuthenticated {
                if appState.currentUser != nil {
                    AuthenticationView()
                } else {
                    OnboardingView()
                }
            } else {
                MainContentView()
                    .onAppear {
                        if !showingWelcomeBack && appState.currentUser != nil {
                            showingWelcomeBack = true
                        }
                    }
            }
        }
        .onAppear {
            let settings = UserDefaults.standard
            if settings.bool(forKey: "securityEnabled") && !appState.isAuthenticated && !appState.disguiseMode {
                showingAuth = true
            }
            
            notificationManager.resetBadgeCount()
            
            reportStore.checkForUpdates()
            notificationManager.checkForReportNotifications(reports: reportStore.activeReports)
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingWelcomeBack) {
            WelcomeBackView()
        }
        .onChange(of: appState.isAuthenticated, { _, _ in
            showingAuth = false
        })
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Enter Access Code")
                .font(.title)
                .padding()
            
            HStack {
                ForEach(0..<4) { _ in
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            
            Spacer()
            
            Text("Numeric keypad placeholder")
            
            Spacer()
            
            Button("Emergency Exit") {
                appState.disguiseMode = true
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}

struct DisguiseRouter: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let disguiseType = getUserDisguiseType()
        
        switch disguiseType {
        case .calculator:
            CalculatorDisguiseView()
        case .weather:
            WeatherDisguiseView()
        case .notes:
            NotesDisguiseView()
        case .utility:
            UtilityDisguiseView()
        }
    }
    
    private func getUserDisguiseType() -> UserPreferences.DisguiseType {
        if let user = appState.currentUser {
            return user.preferences.disguiseType
        } else {
            if let preferences = UserDataService.shared.loadUserPreferences() {
                return preferences.disguiseType
            } else {
                return .calculator
            }
        }
    }
}
