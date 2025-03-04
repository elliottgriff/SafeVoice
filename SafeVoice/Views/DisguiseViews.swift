//
//  WeatherDisguiseView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI
import Combine

struct CalculatorDisguiseView: View {
    @EnvironmentObject var appState: AppState
    @State private var displayValue = "0"
    @State private var previousTaps = [String]()
    @State private var secretCode = ["7", "7", "7", "9"] // secret code to access real app
    
    // Calculator button styles
    struct CalculatorButton: View {
        var label: String
        var color: Color
        var width: CGFloat = 70
        var action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(label)
                    .font(.title)
                    .frame(width: width, height: 70)
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(35)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            HStack {
                Spacer()
                Text(displayValue)
                    .font(.system(size: 64))
                    .fontWeight(.light)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CalculatorButton(label: "C", color: .gray) {
                        displayValue = "0"
                        previousTaps.removeAll()
                    }
                    CalculatorButton(label: "+/-", color: .gray) {
                        addToDisplay("+/-")
                    }
                    CalculatorButton(label: "%", color: .gray) {
                        addToDisplay("%")
                    }
                    CalculatorButton(label: "÷", color: .orange) {
                        addToDisplay("/")
                    }
                }
                
                HStack(spacing: 12) {
                    CalculatorButton(label: "7", color: .darkGray) {
                        addToDisplay("7")
                        checkSecretCode("7")
                    }
                    CalculatorButton(label: "8", color: .darkGray) {
                        addToDisplay("8")
                        checkSecretCode("8")
                    }
                    CalculatorButton(label: "9", color: .darkGray) {
                        addToDisplay("9")
                        checkSecretCode("9")
                    }
                    CalculatorButton(label: "×", color: .orange) {
                        addToDisplay("*")
                    }
                }
                
                HStack(spacing: 12) {
                    CalculatorButton(label: "4", color: .darkGray) {
                        addToDisplay("4")
                        checkSecretCode("4")
                    }
                    CalculatorButton(label: "5", color: .darkGray) {
                        addToDisplay("5")
                        checkSecretCode("5")
                    }
                    CalculatorButton(label: "6", color: .darkGray) {
                        addToDisplay("6")
                        checkSecretCode("6")
                    }
                    CalculatorButton(label: "−", color: .orange) {
                        addToDisplay("-")
                    }
                }
                
                HStack(spacing: 12) {
                    CalculatorButton(label: "1", color: .darkGray) {
                        addToDisplay("1")
                        checkSecretCode("1")
                    }
                    CalculatorButton(label: "2", color: .darkGray) {
                        addToDisplay("2")
                        checkSecretCode("2")
                    }
                    CalculatorButton(label: "3", color: .darkGray) {
                        addToDisplay("3")
                        checkSecretCode("3")
                    }
                    CalculatorButton(label: "+", color: .orange) {
                        addToDisplay("+")
                    }
                }
                
                HStack(spacing: 12) {
                    CalculatorButton(label: "0", color: .darkGray, width: 152) {
                        addToDisplay("0")
                        checkSecretCode("0")
                    }
                    CalculatorButton(label: ".", color: .darkGray) {
                        addToDisplay(".")
                    }
                    CalculatorButton(label: "=", color: .orange) {
                        calculateResult()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        
        // Hidden button for emergency access
        .overlay(
            GeometryReader { geometry in
                VStack {
                    HStack {
                        ZStack {
                            // Invisible button in top left corner - tap 3 times quickly to access
                            Button(action: {
                                checkEmergencyTap()
                            }) {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 60, height: 60)
                            }
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding(.leading, 10)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        )
    }
    
    // Check if secret code has been entered
    private func checkSecretCode(_ digit: String) {
        previousTaps.append(digit)
        
        // Only keep track of the last 4 digits
        if previousTaps.count > 4 {
            previousTaps.removeFirst()
        }
        
        // Check if secret code matches
        if previousTaps == secretCode {
            withAnimation {
                appState.disguiseMode = false
                appState.isAuthenticated = true
            }
        }
    }
    
    // Track emergency tap pattern for quick exit (implement with timing)
    @State private var emergencyTapCount = 0
    @State private var lastTapTime = Date()
    
    private func checkEmergencyTap() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTapTime)
        
        // If taps are within 0.8 seconds of each other
        if timeInterval < 0.8 {
            emergencyTapCount += 1
        } else {
            emergencyTapCount = 1
        }
        
        lastTapTime = now
        
        // Three rapid taps triggers access
        if emergencyTapCount >= 3 {
            withAnimation {
                appState.disguiseMode = false
                emergencyTapCount = 0
            }
        }
    }
    
    // Simple calculator functions
    private func addToDisplay(_ value: String) {
        if displayValue == "0" {
            displayValue = value
        } else {
            displayValue += value
        }
    }
    
    private func calculateResult() {
        displayValue = "42"
    }
}

extension Color {
    static let darkGray = Color(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
}

struct WeatherDisguiseView: View {
    @EnvironmentObject var appState: AppState
    @State private var secretTapCount = 0
    @State private var lastTapTime = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Weather")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    checkSecretTap()
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            
            VStack(spacing: 10) {
                Text("San Francisco")
                    .font(.title2)
                
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("68°")
                    .font(.system(size: 70))
                    .fontWeight(.thin)
                
                Text("Partly Cloudy")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    WeatherDataItem(value: "58°", label: "Low")
                    WeatherDataItem(value: "72°", label: "High")
                    WeatherDataItem(value: "6mph", label: "Wind")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("7-Day Forecast")
                    .font(.headline)
                    .padding(.horizontal)
                
                Divider()
                
                ForEach(0..<5) { day in
                    ForecastRow(day: day)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Check for secret tap pattern
    private func checkSecretTap() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTapTime)
        
        if timeInterval < 0.5 {
            secretTapCount += 1
        } else {
            secretTapCount = 1
        }
        
        lastTapTime = now
        
        if secretTapCount >= 3 {
            withAnimation {
                appState.disguiseMode = false
                secretTapCount = 0
            }
        }
    }
}

struct WeatherDataItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
    }
}

struct ForecastRow: View {
    let day: Int
    
    var body: some View {
        HStack {
            Text(dayName)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Image(systemName: weatherIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            Spacer()
            
            Text("\(lowTemp)°")
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            Text("\(highTemp)°")
                .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var dayName: String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        return days[(today + day) % 7]
    }
    
    private var weatherIcon: String {
        let icons = ["sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill", "cloud.sun.fill"]
        return icons[day % icons.count]
    }
    
    private var lowTemp: Int {
        return [58, 59, 57, 56, 60, 62, 59][day % 7]
    }
    
    private var highTemp: Int {
        return [72, 71, 69, 65, 68, 73, 70][day % 7]
    }
}

struct NotesDisguiseView: View {
    @EnvironmentObject var appState: AppState
    @State private var notes = [
        Note(title: "Shopping List", content: "Milk\nEggs\nBread\nApples\nBananas"),
        Note(title: "Meeting Notes", content: "Discuss project timeline\nReview budget\nAssign tasks"),
        Note(title: "Gift Ideas", content: "Mom: Scarf\nDad: Book\nSister: Earrings"),
    ]
    @State private var secretTapCount = 0
    @State private var lastTapTime = Date()
    @State private var selectedNote: Note?
    
    struct Note: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let date = Date().addingTimeInterval(-Double.random(in: 0...604800))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    Button(action: {
                        selectedNote = note
                    }) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.title)
                                .font(.headline)
                            
                            Text(note.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Text(formattedDate(note.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarItems(
                leading: Button(action: {
                    checkSecretTap()
                }) {
                    Image(systemName: "gear")
                },
                trailing: Button(action: {
                }) {
                    Image(systemName: "square.and.pencil")
                }
            )
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func checkSecretTap() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTapTime)
        
        if timeInterval < 0.5 {
            secretTapCount += 1
        } else {
            secretTapCount = 1
        }
        
        lastTapTime = now
        
        if secretTapCount >= 3 {
            withAnimation {
                appState.disguiseMode = false
                secretTapCount = 0
            }
        }
    }
}

struct NoteDetailView: View {
    let note: NotesDisguiseView.Note
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(note.content)
                        .padding()
                }
            }
            .navigationTitle(note.title)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct UtilityDisguiseView: View {
    @EnvironmentObject var appState: AppState
    @State private var secretTapCount = 0
    @State private var lastTapTime = Date()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Daily Tools")) {
                    UtilityButton(icon: "flashlight.on.fill", title: "Flashlight", action: {})
                    UtilityButton(icon: "ruler.fill", title: "Measure", action: {})
                    UtilityButton(icon: "level.fill", title: "Level", action: {})
                }
                
                Section(header: Text("Converters")) {
                    UtilityButton(icon: "dollarsign.circle.fill", title: "Currency Converter", action: {})
                    UtilityButton(icon: "scalemass.fill", title: "Unit Converter", action: {})
                    UtilityButton(icon: "clock.fill", title: "Time Zone Converter", action: {})
                }
                
                Section(header: Text("Math Tools")) {
                    UtilityButton(icon: "function", title: "Calculator", action: {})
                    UtilityButton(icon: "percent", title: "Percentage Calculator", action: {})
                    UtilityButton(icon: "divide", title: "Split Bill Calculator", action: {})
                }
                
                Section(header: Text("Settings")) {
                    Button(action: {
                        checkSecretTap()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Preferences")
                        }
                    }
                }
            }
            .navigationTitle("Utilities")
        }
    }
    
    private func checkSecretTap() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTapTime)
        
        if timeInterval < 0.5 {
            secretTapCount += 1
        } else {
            secretTapCount = 1
        }
        
        lastTapTime = now
        
        if secretTapCount >= 3 {
            withAnimation {
                appState.disguiseMode = false
                secretTapCount = 0
            }
        }
    }
}

struct UtilityButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                Text(title)
            }
        }
    }
}
