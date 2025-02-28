//
//  User.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import LocalAuthentication

// User model
struct User: Identifiable, Codable {
    var id: String
    var anonymousID: String
    var displayName: String?
    var preferences: UserPreferences
    var createdAt: Date
    var lastLoginAt: Date
    
    // Create a new user with default settings
    static func createNew(displayName: String? = nil) -> User {
        return User(
            id: UUID().uuidString,
            anonymousID: UUID().uuidString,
            displayName: displayName,
            preferences: UserPreferences(),
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
    
    // Create an anonymous user
    static func createAnonymous() -> User {
        return User(
            id: UUID().uuidString,
            anonymousID: UUID().uuidString,
            displayName: nil,
            preferences: UserPreferences(useDisguiseByDefault: true, preferredAuthMethod: .none),
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
}

// User preferences model
struct UserPreferences: Codable {
    var useDisguiseByDefault: Bool = false
    var startInIncognitoMode: Bool = false
    var preferredAuthMethod: AuthMethod = .none
    var disguiseType: DisguiseType = .calculator
    var customAppName: String = "Calculator"
    var allowNotifications: Bool = true
    var disguiseNotifications: Bool = true
    var emergencyOptions: EmergencyOptions = EmergencyOptions()
    var dataProtectionOptions: DataProtectionOptions = DataProtectionOptions()
    
    // Authentication method enum
    enum AuthMethod: String, Codable {
        case none, biometric, passcode
    }
    
    // Disguise type enum
    enum DisguiseType: String, Codable {
        case calculator, weather, notes, utility
        
        var displayName: String {
            switch self {
            case .calculator: return "Calculator"
            case .weather: return "Weather App"
            case .notes: return "Notes App"
            case .utility: return "Utility App"
            }
        }
        
        var icon: String {
            switch self {
            case .calculator: return "function"
            case .weather: return "cloud.sun.fill"
            case .notes: return "note.text"
            case .utility: return "wrench.and.screwdriver.fill"
            }
        }
    }
}

// Emergency options model
struct EmergencyOptions: Codable {
    var enableShakeToExit: Bool = true
    var enableEmergencyTap: Bool = true
    var enableDuressCode: Bool = false
    var duressCode: String = ""
    var clearDataOnDuress: Bool = true
}

// Data protection options model
struct DataProtectionOptions: Codable {
    var autoDeleteReportsAfterDays: Int = 30
    var wipeDataAfterFailedAttempts: Bool = false
    var maxFailedAttempts: Int = 10
    var incognitoMode: Bool = false
}

// Authentication service
class AuthService {
    // Singleton instance
    static let shared = AuthService()
    
    private init() {}
    
    // Authenticate user with passcode
    func authenticateWithPasscode(passcode: String, storedPasscode: String, completion: @escaping (Bool) -> Void) {
        // Simple passcode check for demo purposes
        // In a real app, would use secure hashing
        let isAuthenticated = passcode == storedPasscode
        completion(isAuthenticated)
    }
    
    // Authenticate user with biometrics
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your SafeVoice account"
            
            // Authenticate with biometrics
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else {
            // Biometric authentication not available
            completion(false, error)
        }
    }
    
    // Generate secure token for anonymous identification
    func generateAnonymousToken() -> String {
        // In a real app, would implement a more sophisticated token generation
        return UUID().uuidString + "-" + String(Date().timeIntervalSince1970)
    }
    
    // Hash passcode for secure storage
    func hashPasscode(_ passcode: String) -> String {
        // In a real app, would use a secure hashing algorithm with salt
        // This is just a placeholder
        return passcode
    }
}

// User data service
class UserDataService {
    // Singleton instance
    static let shared = UserDataService()
    
    private init() {}
    
    // UserDefaults keys
    private enum Keys {
        static let currentUser = "currentUser"
        static let userSettings = "userSettings"
        static let passcode = "userPasscode"
    }
    
    // Save user to UserDefaults
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: Keys.currentUser)
        }
    }
    
    // Load user from UserDefaults
    func loadUser() -> User? {
        if let userData = UserDefaults.standard.data(forKey: Keys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            return user
        }
        return nil
    }
    
    // Save user preferences
    func saveUserPreferences(_ preferences: UserPreferences) {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: Keys.userSettings)
        }
    }
    
    // Load user preferences
    func loadUserPreferences() -> UserPreferences? {
        if let prefsData = UserDefaults.standard.data(forKey: Keys.userSettings),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: prefsData) {
            return preferences
        }
        return nil
    }
    
    // Save passcode securely
    // Note: In a real app, would use Keychain instead of UserDefaults
    func savePasscode(_ passcode: String) {
        let hashedPasscode = AuthService.shared.hashPasscode(passcode)
        UserDefaults.standard.set(hashedPasscode, forKey: Keys.passcode)
    }
    
    // Get saved passcode
    func getPasscode() -> String? {
        return UserDefaults.standard.string(forKey: Keys.passcode)
    }
    
    // Delete all user data
    func deleteAllUserData() {
        UserDefaults.standard.removeObject(forKey: Keys.currentUser)
        UserDefaults.standard.removeObject(forKey: Keys.userSettings)
        UserDefaults.standard.removeObject(forKey: Keys.passcode)
    }
}

// For a complete implementation, these user-related functions would be integrated
// with the AppState class to manage authentication state throughout the app
extension AppState {
    // Create and log in as anonymous user
    func createAnonymousUser() {
        let anonymousUser = User.createAnonymous()
        self.currentUser = anonymousUser
        self.isAuthenticated = true
        UserDataService.shared.saveUser(anonymousUser)
    }
    
    // Create and log in as registered user
    func createUser(displayName: String? = nil, preferences: UserPreferences) {
        var newUser = User.createNew(displayName: displayName)
        newUser.preferences = preferences
        self.currentUser = newUser
        self.isAuthenticated = true
        UserDataService.shared.saveUser(newUser)
        UserDataService.shared.saveUserPreferences(preferences)
    }
    
    // Update user preferences
    func updateUserPreferences(_ preferences: UserPreferences) {
        guard var user = self.currentUser else { return }
        user.preferences = preferences
        self.currentUser = user
        UserDataService.shared.saveUser(user)
        UserDataService.shared.saveUserPreferences(preferences)
        
        // Update app state based on preferences
        if preferences.useDisguiseByDefault {
            self.disguiseMode = true
        }
    }
    
    // Update passcode
    func updatePasscode(_ passcode: String) {
        UserDataService.shared.savePasscode(passcode)
    }
    
    // Attempt authentication with passcode
    func authenticateWithPasscode(_ passcode: String, completion: @escaping (Bool) -> Void) {
        guard let storedPasscode = UserDataService.shared.getPasscode() else {
            completion(false)
            return
        }
        
        AuthService.shared.authenticateWithPasscode(
            passcode: AuthService.shared.hashPasscode(passcode),
            storedPasscode: storedPasscode,
            completion: completion
        )
    }
    
    // Attempt authentication with biometrics
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        AuthService.shared.authenticateWithBiometrics { success, error in
            if success {
                self.isAuthenticated = true
            }
            completion(success)
        }
    }
    
    // Complete logout and data cleanup
    func secureLogout(clearData: Bool = false) {
        self.isAuthenticated = false
        
        if clearData {
            UserDataService.shared.deleteAllUserData()
            self.currentUser = nil
        }
        
        // Switch to disguise mode for additional security
        self.disguiseMode = true
    }
    
    // Load saved user state from persistent storage
    func loadSavedUserState() {
        if let user = UserDataService.shared.loadUser() {
            self.currentUser = user
            
            // Check if app should start in disguise mode
            if user.preferences.useDisguiseByDefault {
                self.disguiseMode = true
            } else {
                // Otherwise check if authentication is required
                if user.preferences.preferredAuthMethod != .none {
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = true
                }
            }
        }
    }
}
