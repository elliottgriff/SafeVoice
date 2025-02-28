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
    
    // Setup initial app state
    private func setupApp() {
        // Load saved user state
        appState.loadSavedUserState()
        
        // If no user is loaded, check if we should start in disguise mode
        if appState.currentUser == nil {
            let settings = UserDefaults.standard
            if settings.bool(forKey: "startInDisguiseMode") {
                appState.disguiseMode = true
            }
        }
        
        // Check for report updates periodically
        startUpdateChecks()
    }
    
    // Schedule periodic update checks
    private func startUpdateChecks() {
        // Check for report updates every 10 minutes when app is running
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            reportStore.checkForUpdates()
            
            // Check if any updates should trigger notifications
            NotificationManager.shared.checkForReportNotifications(reports: reportStore.activeReports)
        }
    }
}

// Enhanced App State to support more features
class AppState: ObservableObject {
    // Main app state
    @Published var isAuthenticated = false
    @Published var disguiseMode = false
    @Published var currentUser: User?
    
    // Navigation state
    @Published var selectedTab = 0
    @Published var showingNewReport = false
    @Published var showingAllReports = false
    @Published var showingNotifications = false
    @Published var showingSettings = false
    @Published var showingProfile = false
    
    // Current view details
    @Published var selectedReportID: String?
    @Published var selectedResourceID: String?
    
    // App mode tracking
    @Published var isInEmergencyMode = false
    @Published var isInIncognitoMode = false
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Toggle between normal and disguise mode
    func toggleDisguiseMode() {
        disguiseMode.toggle()
        
        // If exiting disguise mode, check if authentication is needed
        if !disguiseMode {
            checkAuthentication()
        }
    }
    
    // Check if authentication is needed
    private func checkAuthentication() {
        let settings = UserDefaults.standard
        let securityEnabled = settings.bool(forKey: "securityEnabled")
        
        // If security is enabled, require authentication
        if securityEnabled && currentUser != nil {
            isAuthenticated = false
        }
    }
    
    // Activate emergency mode
    func activateEmergencyMode() {
        isInEmergencyMode = true
        disguiseMode = true
        
        // If incognito mode is enabled, also clear data
        if isInIncognitoMode {
            clearSensitiveData()
        }
    }
    
    // Clear sensitive data in emergency
    private func clearSensitiveData() {
        // Implement based on user settings
        let shouldClearData = UserDefaults.standard.bool(forKey: "clearDataOnEmergency")
        if shouldClearData {
            // Would clear reports, history, etc.
        }
    }
    
    // Reset to default app state
    func resetAppState() {
        isAuthenticated = false
        disguiseMode = false
        currentUser = nil
        selectedTab = 0
        isInEmergencyMode = false
        isInIncognitoMode = false
    }
}

// Main app coordinator
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
                // Show appropriate disguise view based on settings
                DisguiseRouter()
            } else if !appState.isAuthenticated {
                // If not authenticated, show onboarding or auth
                if appState.currentUser != nil {
                    AuthenticationView()
                } else {
                    OnboardingView()
                }
            } else {
                // Main app content
                MainContentView()
                    .onAppear {
                        if !showingWelcomeBack && appState.currentUser != nil {
                            showingWelcomeBack = true
                        }
                    }
            }
        }
        .onAppear {
            // Check if security is needed
            let settings = UserDefaults.standard
            if settings.bool(forKey: "securityEnabled") && !appState.isAuthenticated && !appState.disguiseMode {
                showingAuth = true
            }
            
            // Reset badge count when app opens
            notificationManager.resetBadgeCount()
            
            // Check for report updates
            reportStore.checkForUpdates()
            notificationManager.checkForReportNotifications(reports: reportStore.activeReports)
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingWelcomeBack) {
            WelcomeBackView()
        }
        .onChange(of: appState.isAuthenticated) { newValue in
            // Reset showing auth when authentication changes
            showingAuth = false
        }
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
            
            // Simplified passcode implementation for prototype
            HStack {
                ForEach(0..<4) { _ in
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            
            Spacer()
            
            // Numeric keypad would go here
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

// Disguise router to show appropriate disguise view
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
    
    // Get user's preferred disguise type
    private func getUserDisguiseType() -> UserPreferences.DisguiseType {
        if let user = appState.currentUser {
            return user.preferences.disguiseType
        } else {
            // Default to calculator if no user preferences
            if let preferences = UserDataService.shared.loadUserPreferences() {
                return preferences.disguiseType
            } else {
                return .calculator
            }
        }
    }
}
