//
//  SettingsView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDisguiseOptions = false
    @State private var showingSecurityOptions = false
    @State private var showingPrivacyPolicy = false
    @State private var showingEmergencyOptions = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // Disguise options
                Section(header: Text("App Appearance")) {
                    Button(action: {
                        showingDisguiseOptions = true
                    }) {
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.blue)
                            Text("Disguise App")
                            Spacer()
                            Text(viewModel.disguiseType.displayName)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Toggle("Start in Disguise Mode", isOn: $viewModel.startInDisguiseMode)
                        .onChange(of: viewModel.startInDisguiseMode) { newValue in
                            viewModel.saveSettings()
                        }
                    
                    HStack {
                        Button(action: {
                            // Quick test of disguise mode
                            appState.toggleDisguiseMode()
                        }) {
                            Text("Test Disguise Mode")
                        }
                    }
                }
                
                // Security options
                Section(header: Text("Security")) {
                    Button(action: {
                        showingSecurityOptions = true
                    }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("App Security")
                            Spacer()
                            Text(viewModel.securityMethod.displayName)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showingEmergencyOptions = true
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Emergency Options")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Data privacy
                Section(header: Text("Privacy")) {
                    Toggle("Incognito Mode", isOn: $viewModel.incognitoMode)
                        .onChange(of: viewModel.incognitoMode) { newValue in
                            viewModel.saveSettings()
                        }
                    
                    if viewModel.incognitoMode {
                        Text("App will not store any report data on your device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete All Local Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Notifications (for follow-ups)
                Section(header: Text("Notifications")) {
                    Toggle("Allow Notifications", isOn: $viewModel.allowNotifications)
                        .onChange(of: viewModel.allowNotifications) { newValue in
                            viewModel.saveSettings()
                            viewModel.updateNotificationPermissions()
                        }
                    
                    if viewModel.allowNotifications {
                        Toggle("Disguise Notifications", isOn: $viewModel.disguiseNotifications)
                            .onChange(of: viewModel.disguiseNotifications) { newValue in
                                viewModel.saveSettings()
                            }
                        
                        Text("Notifications will appear as \"Calendar Reminders\" instead of using the app name.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // About and Help
                Section(header: Text("About")) {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Link(destination: URL(string: "https://safevoice.org/help")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // App version
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingDisguiseOptions) {
                DisguiseOptionsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSecurityOptions) {
                SecurityOptionsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEmergencyOptions) {
                EmergencyOptionsView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("This will permanently delete all reports, drafts, and settings. This action cannot be undone.")
            }
        }
    }
}

// ViewModel for Settings
class SettingsViewModel: ObservableObject {
    enum DisguiseType: String, CaseIterable {
        case calculator = "calculator"
        case weather = "weather"
        case notes = "notes"
        case utility = "utility"
        
        var displayName: String {
            switch self {
            case .calculator: return "Calculator"
            case .weather: return "Weather App"
            case .notes: return "Notes App"
            case .utility: return "Utility App"
            }
        }
    }
    
    enum SecurityMethod: String, CaseIterable {
        case none = "none"
        case passcode = "passcode"
        case biometric = "biometric"
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .passcode: return "Passcode"
            case .biometric: return "Face ID/Touch ID"
            }
        }
    }
    
    // Published properties
    @Published var disguiseType: DisguiseType = .calculator
    @Published var securityMethod: SecurityMethod = .none
    @Published var startInDisguiseMode: Bool = false
    @Published var incognitoMode: Bool = false
    @Published var allowNotifications: Bool = true
    @Published var disguiseNotifications: Bool = true
    @Published var passcode: String = ""
    
    // Biometric authentication context
    private let context = LAContext()
    
    init() {
        loadSettings()
    }
    
    // Save settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(disguiseType.rawValue, forKey: "disguiseType")
        defaults.set(securityMethod.rawValue, forKey: "securityMethod")
        defaults.set(startInDisguiseMode, forKey: "startInDisguiseMode")
        defaults.set(incognitoMode, forKey: "incognitoMode")
        defaults.set(allowNotifications, forKey: "allowNotifications")
        defaults.set(disguiseNotifications, forKey: "disguiseNotifications")
        
        // Don't save passcode in UserDefaults - in a real app, use Keychain
        if !passcode.isEmpty {
            // This is a placeholder - use Keychain in real implementation
            // secureStorePasscode(passcode)
        }
    }
    
    // Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let rawDisguiseType = defaults.string(forKey: "disguiseType"),
           let type = DisguiseType(rawValue: rawDisguiseType) {
            disguiseType = type
        }
        
        if let rawSecurityMethod = defaults.string(forKey: "securityMethod"),
           let method = SecurityMethod(rawValue: rawSecurityMethod) {
            securityMethod = method
        }
        
        startInDisguiseMode = defaults.bool(forKey: "startInDisguiseMode")
        incognitoMode = defaults.bool(forKey: "incognitoMode")
        allowNotifications = defaults.bool(forKey: "allowNotifications")
        disguiseNotifications = defaults.bool(forKey: "disguiseNotifications")
        
        // Load passcode from Keychain in real implementation
    }
    
    // Update notification permissions
    func updateNotificationPermissions() {
        // In a real app, we would request notification permissions here
        // UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        //     // Handle result
        // }
    }
    
    // Delete all user data
    func deleteAllData() {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        
        // Reset state
        disguiseType = .calculator
        securityMethod = .none
        startInDisguiseMode = false
        incognitoMode = false
        allowNotifications = true
        disguiseNotifications = true
        passcode = ""
        
        // In a real app, we would delete any Core Data records/Keychain items here
    }
    
    // Check if biometric authentication is available
    func canUseBiometrics() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}

// Disguise options view
struct DisguiseOptionsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Choose Disguise")) {
                    ForEach(SettingsViewModel.DisguiseType.allCases, id: \.self) { type in
                        Button(action: {
                            viewModel.disguiseType = type
                            viewModel.saveSettings()
                        }) {
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                if viewModel.disguiseType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Disguise Icon"), footer: Text("Choose how the app appears on your home screen.")) {
                    // App icon options would go here
                    Text("Standard Icon (Default)")
                    Text("Calculator Icon")
                    Text("Notes Icon")
                    Text("Utilities Icon")
                }
                
                Section(footer: Text("Customizing the app name will change how it appears on your home screen.")) {
                    TextField("Custom App Name", text: .constant("Calculator"))
                }
            }
            .navigationTitle("Disguise Options")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// Security options view
struct SecurityOptionsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPasscodeSheet = false
    @State private var biometricPromptShowing = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Access Security")) {
                    ForEach(SettingsViewModel.SecurityMethod.allCases, id: \.self) { method in
                        Button(action: {
                            selectSecurityMethod(method)
                        }) {
                            HStack {
                                Text(method.displayName)
                                Spacer()
                                if viewModel.securityMethod == method {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(method == .biometric && !viewModel.canUseBiometrics())
                    }
                    
                    if !viewModel.canUseBiometrics() && SettingsViewModel.SecurityMethod.allCases.contains(.biometric) {
                        Text("Biometric authentication is not available on this device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if viewModel.securityMethod != .none {
                    Section(header: Text("Security Settings")) {
                        Stepper("Auto-Lock After: 5 minutes", value: .constant(5), in: 1...30)
                        
                        Toggle("Require Authentication After Background", isOn: .constant(true))
                        
                        if viewModel.securityMethod == .passcode {
                            Button("Change Passcode") {
                                showingPasscodeSheet = true
                            }
                        }
                    }
                    
                    Section(header: Text("Panic Button")) {
                        Toggle("Enable 3 Wrong Attempts", isOn: .constant(true))
                        
                        Text("If someone enters the wrong passcode 3 times, the app will automatically switch to disguise mode.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Security Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingPasscodeSheet) {
                PasscodeSetupView(viewModel: viewModel)
            }
            .alert("Setup Face ID/Touch ID", isPresented: $biometricPromptShowing) {
                Button("Cancel", role: .cancel) {
                    viewModel.securityMethod = .none
                    viewModel.saveSettings()
                }
                Button("Enable") {
                    // In a real app, we would set up biometrics here
                    viewModel.securityMethod = .biometric
                    viewModel.saveSettings()
                }
            } message: {
                Text("This will use Face ID/Touch ID to protect access to the app.")
            }
        }
    }
    
    private func selectSecurityMethod(_ method: SettingsViewModel.SecurityMethod) {
        switch method {
        case .none:
            viewModel.securityMethod = .none
            viewModel.saveSettings()
        case .passcode:
            showingPasscodeSheet = true
        case .biometric:
            biometricPromptShowing = true
        }
    }
}

// Passcode setup view
struct PasscodeSetupView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var showingConfirmation = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(showingConfirmation ? "Confirm Passcode" : "Create Passcode")
                    .font(.title)
                    .padding(.top, 40)
                
                Text(showingConfirmation ? "Enter the passcode again to confirm" : "Choose a 4-digit passcode to secure your app")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Passcode dots
                HStack(spacing: 20) {
                    ForEach(0..<4) { index in
                        Circle()
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 16, height: 16)
                                    .opacity(dotOpacity(at: index))
                            )
                    }
                }
                .padding(.bottom, 40)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Number pad
                VStack(spacing: 15) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 30) {
                            ForEach(1..<4) { col in
                                let number = row * 3 + col
                                Button(action: {
                                    addDigit(number)
                                }) {
                                    Text("\(number)")
                                        .font(.title)
                                        .frame(width: 70, height: 70)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 30) {
                        // Empty space for layout
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 70, height: 70)
                        
                        Button(action: {
                            addDigit(0)
                        }) {
                            Text("0")
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            deleteDigit()
                        }) {
                            Image(systemName: "delete.left")
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    // Helper to determine if a dot should be filled
    private func dotOpacity(at index: Int) -> Double {
        let currentPasscode = showingConfirmation ? confirmPasscode : passcode
        return index < currentPasscode.count ? 1 : 0
    }
    
    // Add digit to passcode
    private func addDigit(_ digit: Int) {
        let currentPasscode = showingConfirmation ? confirmPasscode : passcode
        
        if currentPasscode.count < 4 {
            if showingConfirmation {
                confirmPasscode += "\(digit)"
                
                // Check if confirmation is complete
                if confirmPasscode.count == 4 {
                    validatePasscodes()
                }
            } else {
                passcode += "\(digit)"
                
                // Move to confirmation after 4 digits
                if passcode.count == 4 {
                    showingConfirmation = true
                }
            }
        }
    }
    
    // Delete last digit
    private func deleteDigit() {
        if showingConfirmation {
            if !confirmPasscode.isEmpty {
                confirmPasscode.removeLast()
            }
        } else {
            if !passcode.isEmpty {
                passcode.removeLast()
            }
        }
        
        // Clear error message when editing
        errorMessage = nil
    }
    
    // Validate passcodes match
    private func validatePasscodes() {
        if passcode == confirmPasscode {
            viewModel.passcode = passcode
            viewModel.securityMethod = .passcode
            viewModel.saveSettings()
            dismiss()
        } else {
            errorMessage = "Passcodes don't match. Try again."
            // Reset for retry
            showingConfirmation = false
            confirmPasscode = ""
            passcode = ""
        }
    }
}

// Emergency options view
struct EmergencyOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Exit")) {
                    Toggle("Emergency Triple Tap", isOn: .constant(true))
                    Text("Triple-tapping the top-left corner will immediately switch to disguise mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Shake to Exit", isOn: .constant(true))
                    Text("Quickly shaking your device will switch to disguise mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Duress Access")) {
                    Toggle("Duress Passcode", isOn: .constant(true))
                    Text("Set an alternate passcode that will open the app in disguise mode and erase sensitive data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Set Duress Passcode") {
                        // Would show passcode setting UI
                    }
                }
                
                Section(header: Text("Data Protection")) {
                    Toggle("Auto-Delete Reports After 30 Days", isOn: .constant(true))
                    
                    Toggle("Wipe Data After 10 Failed Attempts", isOn: .constant(false))
                    Text("Warning: This will permanently delete all app data if someone enters the wrong passcode 10 times.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Emergency Options")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// Privacy policy view
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        Text("At SafeVoice, we take your privacy very seriously, especially given the sensitive nature of the information shared through our app.")
                        
                        Text("Information Collection and Use")
                            .font(.headline)
                        
                        Text("When you submit an anonymous report, we collect only the information you choose to provide. This may include:")
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• Details about incidents you're reporting")
                            Text("• Photos or other media you upload")
                            Text("• Optional contact information (only if you choose)")
                        }
                        
                        Text("Anonymous Reports")
                            .font(.headline)
                        
                        Text("When you submit a report anonymously, we take multiple steps to protect your identity:")
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• No personal identifiers are required")
                            Text("• IP addresses are not stored with reports")
                            Text("• Device information is stripped from uploads")
                            Text("• All data is encrypted end-to-end")
                        }
                    }
                    
                    Group {
                        Text("Data Security")
                            .font(.headline)
                        
                        Text("We employ industry-standard security measures to protect your data, including:")
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• 256-bit AES encryption for all data")
                            Text("• Secure, isolated database infrastructure")
                            Text("• Regular security audits and penetration testing")
                            Text("• Limited employee access to report data")
                        }
                        
                        Text("Data Sharing")
                            .font(.headline)
                        
                        Text("Reports are shared only with the appropriate agencies required to investigate and respond to the reported incidents. This may include child protective services, school officials, or law enforcement. We do not share data with third parties for commercial purposes.")
                        
                        Text("Your Rights")
                            .font(.headline)
                        
                        Text("You have the right to request information about your data, request deletion of your data, and withdraw consent. To exercise these rights, please contact our privacy team.")
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}
