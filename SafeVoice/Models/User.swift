//
//  User.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import LocalAuthentication

struct User: Identifiable, Codable {
    var id: String
    var anonymousID: String
    var displayName: String?
    var preferences: UserPreferences
    var createdAt: Date
    var lastLoginAt: Date
    
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
    
    enum AuthMethod: String, Codable {
        case none, biometric, passcode
    }
    
    
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


struct EmergencyOptions: Codable {
    var enableShakeToExit: Bool = true
    var enableEmergencyTap: Bool = true
    var enableDuressCode: Bool = false
    var duressCode: String = ""
    var clearDataOnDuress: Bool = true
}


struct DataProtectionOptions: Codable {
    var autoDeleteReportsAfterDays: Int = 30
    var wipeDataAfterFailedAttempts: Bool = false
    var maxFailedAttempts: Int = 10
    var incognitoMode: Bool = false
}


class AuthService {
    
    static let shared = AuthService()
    
    private init() {}
    
    
    func authenticateWithPasscode(passcode: String, storedPasscode: String, completion: @escaping (Bool) -> Void) {
        // Simple passcode check for demo purposes
        // In a real app, would use secure hashing
        let isAuthenticated = passcode == storedPasscode
        completion(isAuthenticated)
    }
    
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your SafeVoice account"
            
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else {
            
            completion(false, error)
        }
    }
    
    
    func generateAnonymousToken() -> String {
        // In a real app, would implement a more sophisticated token generation
        return UUID().uuidString + "-" + String(Date().timeIntervalSince1970)
    }
    
    
    func hashPasscode(_ passcode: String) -> String {
        // In a real app, would use a secure hashing algorithm with salt
        // This is just a placeholder
        return passcode
    }
}


class UserDataService {
    
    static let shared = UserDataService()
    
    private init() {}
    
    
    private enum Keys {
        static let currentUser = "currentUser"
        static let userSettings = "userSettings"
        static let passcode = "userPasscode"
    }
    
    
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: Keys.currentUser)
        }
    }
    
    
    func loadUser() -> User? {
        if let userData = UserDefaults.standard.data(forKey: Keys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            return user
        }
        return nil
    }
    
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: Keys.userSettings)
        }
    }
    
    
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
    
    
    func getPasscode() -> String? {
        return UserDefaults.standard.string(forKey: Keys.passcode)
    }
    
    
    func deleteAllUserData() {
        UserDefaults.standard.removeObject(forKey: Keys.currentUser)
        UserDefaults.standard.removeObject(forKey: Keys.userSettings)
        UserDefaults.standard.removeObject(forKey: Keys.passcode)
    }
}



extension AppState {
    
    func createAnonymousUser() {
        let anonymousUser = User.createAnonymous()
        self.currentUser = anonymousUser
        self.isAuthenticated = true
        UserDataService.shared.saveUser(anonymousUser)
    }
    
    
    func createUser(displayName: String? = nil, preferences: UserPreferences) {
        var newUser = User.createNew(displayName: displayName)
        newUser.preferences = preferences
        self.currentUser = newUser
        self.isAuthenticated = true
        UserDataService.shared.saveUser(newUser)
        UserDataService.shared.saveUserPreferences(preferences)
    }
    
    
    func updateUserPreferences(_ preferences: UserPreferences) {
        guard var user = self.currentUser else { return }
        user.preferences = preferences
        self.currentUser = user
        UserDataService.shared.saveUser(user)
        UserDataService.shared.saveUserPreferences(preferences)
        
        
        if preferences.useDisguiseByDefault {
            self.disguiseMode = true
        }
    }
    
    
    func updatePasscode(_ passcode: String) {
        UserDataService.shared.savePasscode(passcode)
    }
    
    
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
    
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        AuthService.shared.authenticateWithBiometrics { success, error in
            if success {
                self.isAuthenticated = true
            }
            completion(success)
        }
    }
    
    
    func secureLogout(clearData: Bool = false) {
        self.isAuthenticated = false
        
        if clearData {
            UserDataService.shared.deleteAllUserData()
            self.currentUser = nil
        }
        
        
        self.disguiseMode = true
    }

    
    func loadSavedUserState() {
        if let user = UserDataService.shared.loadUser() {
            self.currentUser = user
            
            
            if user.preferences.useDisguiseByDefault {
                self.disguiseMode = true
            } else {
                if user.preferences.preferredAuthMethod != .none {
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = true
                }
            }
        }
    }
}
