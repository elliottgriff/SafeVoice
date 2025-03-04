//
//  OnboardingView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    // Onboarding pages content
    private let pages = [
        OnboardingPage(
            title: "Welcome to SafeVoice",
            subtitle: "A safe space to report abuse and get help",
            image: "shield.fill",
            description: "SafeVoice is designed to help kids and teens safely report abuse, bullying, or other concerns and connect with resources."
        ),
        OnboardingPage(
            title: "Your Privacy Matters",
            subtitle: "Report anonymously if you choose",
            image: "hand.raised.fill",
            description: "You can report issues without sharing your name or personal information. Your safety and privacy are our top priorities."
        ),
        OnboardingPage(
            title: "Disguise Mode",
            subtitle: "Keep the app hidden when needed",
            image: "eye.slash.fill",
            description: "Our unique disguise feature makes the app look like a calculator or other harmless app when you need privacy."
        ),
        OnboardingPage(
            title: "Connect With Help",
            subtitle: "Resources when you need them",
            image: "person.3.fill",
            description: "Find local services, hotlines, and educational resources to help you understand your rights and options."
        ),
        OnboardingPage(
            title: "Ready to Begin?",
            subtitle: "Choose how you want to set up SafeVoice",
            image: "checkmark.circle.fill",
            description: "Select the options that will help you feel most safe and comfortable using the app."
        )
    ]
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Content
            VStack {
                // Skip button for all pages except last
                if currentPage < pages.count - 1 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                }
                
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Spacer()
                            

                            Image(systemName: pages[index].image)
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .padding()
                            

                            Text(pages[index].title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].subtitle)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            

                            Text(pages[index].description)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 10)
                            
                            Spacer()
                            

                            if index == pages.count - 1 {
                                setupOptionsView
                            } else {

                                Button(action: {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }) {
                                    Text("Next")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .frame(width: 200, height: 50)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                }
                                .padding(.bottom, 50)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
        }
    }
    

    private var setupOptionsView: some View {
        VStack(spacing: 15) {
            // Create secure profile option
            Button(action: {
                withAnimation {

                    showSecureProfileSetup()
                }
            }) {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Create Secure Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            

            Button(action: {
                withAnimation {

                    showAnonymousSetup()
                }
            }) {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                    Text("Use Anonymously")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.purple)
                .cornerRadius(10)
            }
            

            Button(action: {
                withAnimation {

                    showDisguiseSetup()
                }
            }) {
                HStack {
                    Image(systemName: "eye.slash")
                    Text("Set Up Disguise Mode")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.indigo)
                .cornerRadius(10)
            }
            

            Button(action: {
                withAnimation {

                    completeOnboarding()
                }
            }) {
                Text("Just Explore the App")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
    }
    

    private func showSecureProfileSetup() {

        appState.isAuthenticated = true
    }
    
    private func showAnonymousSetup() {

        appState.isAuthenticated = true
    }
    
    private func showDisguiseSetup() {

        appState.disguiseMode = true
    }
    
    private func completeOnboarding() {
        appState.isAuthenticated = true
    }
}


struct OnboardingPage {
    let title: String
    let subtitle: String
    let image: String
    let description: String
}


struct SecureProfileSetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var usePasscode = true
    @State private var useDisguise = true
    @State private var selectedDisguiseType: DisguiseType = .calculator
    @State private var showingPasscodeSetup = false
    
    enum DisguiseType: String, CaseIterable, Identifiable {
        case calculator, weather, notes, utility
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .calculator: return "Calculator"
            case .weather: return "Weather App"
            case .notes: return "Notes App"
            case .utility: return "Utility App"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Info")) {
                    TextField("Choose a username", text: $username)
                        .autocapitalization(.none)
                    
                    Text("This username will be used only within the app. It won't be shared with anyone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Security")) {
                    Toggle("Protect with Passcode", isOn: $usePasscode)
                    
                    if usePasscode {
                        Button("Set Up Passcode") {
                            showingPasscodeSetup = true
                        }
                        
                        Text("A passcode prevents others from accessing the app without your permission.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Privacy")) {
                    Toggle("Enable Disguise Mode", isOn: $useDisguise)
                    
                    if useDisguise {
                        Picker("Disguise Type", selection: $selectedDisguiseType) {
                            ForEach(DisguiseType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Disguise mode makes the app look like a different app to keep your privacy safe.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        completeSetup()
                    }) {
                        Text("Complete Setup")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Create Profile")
            .sheet(isPresented: $showingPasscodeSetup) {
                PasscodeSetupView(viewModel: settingsViewModel)
            }
        }
    }
    
    private func completeSetup() {

        appState.isAuthenticated = true
        dismiss()
    }
}


struct AnonymousSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var enableQuickExit = true
    @State private var clearDataOnExit = false
    @State private var useDisguiseMode = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Anonymous Settings")) {
                    Text("When using anonymously, no personal information will be saved. You can still create reports and access resources.")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Quick Exit")) {
                    Toggle("Enable Quick Exit Button", isOn: $enableQuickExit)
                    
                    Text("The quick exit button lets you quickly hide the app in case of emergency.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Clear Data on Exit", isOn: $clearDataOnExit)
                    
                    Text("When enabled, your session data will be cleared when you use the quick exit button.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Disguise")) {
                    Toggle("Use Disguise Mode", isOn: $useDisguiseMode)
                    
                    Text("Makes the app look like a calculator or other innocent app when closed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if useDisguiseMode {
                        Button("Configure Disguise") {

                        }
                    }
                }
                
                Section {
                    Button(action: {
                        completeSetup()
                    }) {
                        Text("Start Using Anonymously")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Anonymous Setup")
        }
    }
    
    private func completeSetup() {

        appState.isAuthenticated = true
        dismiss()
    }
}


struct DisguiseSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDisguiseType: DisguiseType = .calculator
    @State private var customAppName = "Calculator"
    @State private var showTutorial = true
    
    enum DisguiseType: String, CaseIterable, Identifiable {
        case calculator, weather, notes, utility
        
        var id: String { self.rawValue }
        
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Disguise Appearance")) {
                    Picker("Choose Disguise", selection: $selectedDisguiseType) {
                        ForEach(DisguiseType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    TextField("Custom App Name", text: $customAppName)
                }
                
                Section(header: Text("Disguise Behavior")) {
                    Toggle("Show Tutorial at First Launch", isOn: $showTutorial)
                    
                    Text("This will show a brief tutorial explaining how to use the disguise to access the real app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("Set Access Code", destination: Text("Access code setup view"))
                    
                    Text("Creates a special key combination to access the real app while in disguise mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Preview")) {
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: selectedDisguiseType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        
                        Text(customAppName)
                            .font(.headline)
                        
                        Text("This is how the app will appear on your home screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section {
                    Button(action: {
                        applyDisguiseAndComplete()
                    }) {
                        Text("Apply Disguise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Disguise Setup")
        }
    }
    
    private func applyDisguiseAndComplete() {

        appState.disguiseMode = true
        dismiss()
    }
}
