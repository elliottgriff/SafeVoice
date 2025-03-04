//
//  ResourcesView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI
import MapKit

struct ResourcesView: View {
    @StateObject private var viewModel = ResourcesViewModel()
    
    var body: some View {
        NavigationView {
            List {
                
                Section(header: Text("Emergency Help")) {
                    NavigationLink(destination: EmergencyContactsView()) {
                        ResourceRowView(
                            icon: "phone.fill",
                            iconColor: .red,
                            title: "Emergency Contacts",
                            description: "Immediate help and crisis support"
                        )
                    }
                }
                
                
                Section(header: Text("Understanding Abuse")) {
                    NavigationLink(destination: AbuseTypesView()) {
                        ResourceRowView(
                            icon: "info.circle",
                            iconColor: .blue,
                            title: "Types of Abuse",
                            description: "Learn about different forms of abuse"
                        )
                    }
                    
                    NavigationLink(destination: SafetyPlanView()) {
                        ResourceRowView(
                            icon: "shield.fill",
                            iconColor: .green,
                            title: "Safety Planning",
                            description: "Steps to stay safe in difficult situations"
                        )
                    }
                    
                    NavigationLink(destination: YourRightsView()) {
                        ResourceRowView(
                            icon: "person.fill.checkmark",
                            iconColor: .indigo,
                            title: "Your Rights",
                            description: "What rights children and teens have"
                        )
                    }
                }
                
                
                if !viewModel.localResources.isEmpty {
                    Section(header: Text("Local Support")) {
                        ForEach(viewModel.localResources) { resource in
                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                ResourceRowView(
                                    icon: iconForResourceType(resource.type),
                                    iconColor: colorForResourceType(resource.type),
                                    title: resource.name,
                                    description: resource.description
                                )
                            }
                        }
                    }
                }
                
                
                Section(header: Text("Find Help")) {
                    NavigationLink(destination: ResourceFinderView()) {
                        ResourceRowView(
                            icon: "mappin.and.ellipse",
                            iconColor: .orange,
                            title: "Find Local Resources",
                            description: "Search for help in your area"
                        )
                    }
                }
            }
            .navigationTitle("Resources")
            .refreshable {
                await viewModel.loadLocalResources()
            }
            .onAppear {
                Task {
                    await viewModel.loadLocalResources()
                }
            }
        }
    }
    
    
    private func iconForResourceType(_ type: Resource.ResourceType) -> String {
        switch type {
        case .shelter: return "house.fill"
        case .counseling: return "person.fill.questionmark"
        case .legalAid: return "building.columns.fill"
        case .childServices: return "person.3.fill"
        case .hotline: return "phone.fill"
        case .medical: return "cross.fill"
        case .police: return "shield.fill"
        case .school: return "book.fill"
        case .other: return "info.circle"
        }
    }
    
    
    private func colorForResourceType(_ type: Resource.ResourceType) -> Color {
        switch type {
        case .shelter: return .indigo
        case .counseling: return .purple
        case .legalAid: return .blue
        case .childServices: return .green
        case .hotline: return .red
        case .medical: return .red
        case .police: return .blue
        case .school: return .orange
        case .other: return .gray
        }
    }
}


struct ResourceRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


class ResourcesViewModel: ObservableObject {
    @Published var localResources: [Resource] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    
    func loadLocalResources() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        
        
        let sampleResources = [
            Resource(
                id: "1",
                name: "Youth Crisis Center",
                type: .shelter,
                description: "Emergency shelter and counseling for youth",
                phoneNumber: "555-123-4567",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "123 Main St",
                    street2: nil,
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "24/7",
                services: ["Emergency shelter", "Counseling", "Family mediation"],
                emergencyService: true,
                latitude: 34.0522,
                longitude: -118.2437,
                distance: 3.5
            ),
            Resource(
                id: "2",
                name: "Teen Counseling Services",
                type: .counseling,
                description: "Free counseling for teens and families",
                phoneNumber: "555-987-6543",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "456 Oak Ave",
                    street2: "Suite 200",
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Fri 9am-7pm",
                services: ["Individual counseling", "Group therapy", "Crisis intervention"],
                emergencyService: false,
                latitude: 34.0530,
                longitude: -118.2445,
                distance: 4.2
            ),
            Resource(
                id: "3",
                name: "Children's Legal Aid",
                type: .legalAid,
                description: "Legal assistance for children and teens",
                phoneNumber: "555-456-7890",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "789 Pine St",
                    street2: nil,
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Fri 9am-5pm",
                services: ["Legal advice", "Court representation", "Advocacy"],
                emergencyService: false,
                latitude: 34.0515,
                longitude: -118.2430,
                distance: 2.8
            )
        ]
        
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            self.localResources = sampleResources
            self.isLoading = false
        }
    }
}


struct EmergencyContactsView: View {
    var body: some View {
        List {
            Section(header: Text("Call for Immediate Help")) {
                EmergencyContactRow(
                    name: "Emergency Services",
                    number: "911",
                    description: "For immediate danger or emergencies",
                    isEmergency: true
                )
                
                EmergencyContactRow(
                    name: "Childhelp National Hotline",
                    number: "1-800-422-4453",
                    description: "24/7 hotline for children at risk",
                    isEmergency: true
                )
                
                EmergencyContactRow(
                    name: "National Runaway Safeline",
                    number: "1-800-786-2929",
                    description: "For youth considering running away",
                    isEmergency: true
                )
            }
            
            Section(header: Text("Text or Chat")) {
                EmergencyContactRow(
                    name: "Crisis Text Line",
                    number: "Text HOME to 741741",
                    description: "Text-based crisis support",
                    isEmergency: false
                )
                
                EmergencyContactRow(
                    name: "National Teen Dating Abuse Helpline",
                    number: "Text LOVEIS to 22522",
                    description: "For relationship abuse concerns",
                    isEmergency: false
                )
            }
            
            Section(header: Text("What to Expect When Calling")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("When you call a hotline:")
                        .font(.headline)
                    
                    Text("• You'll speak with a trained counselor")
                    Text("• They'll listen and ask questions to understand your situation")
                    Text("• You can stay anonymous if you want")
                    Text("• They can connect you with local resources")
                    Text("• In emergencies, they can help coordinate immediate assistance")
                    
                    Text("Remember: These services are here to help you, and calling them is an act of courage. You deserve support.")
                        .padding(.top, 10)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Emergency Contacts")
    }
}


struct EmergencyContactRow: View {
    let name: String
    let number: String
    let description: String
    let isEmergency: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            HStack {
                Text(number)
                    .font(.title3)
                    .bold()
                    .foregroundColor(isEmergency ? .red : .blue)
                
                Spacer()
                
                Button(action: {
                    
                }) {
                    HStack {
                        Image(systemName: isEmergency ? "phone.fill" : "message.fill")
                        Text(isEmergency ? "Call" : "Text")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isEmergency ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}


struct ResourceDetailView: View {
    let resource: Resource
    @State private var region: MKCoordinateRegion
    
    init(resource: Resource) {
        self.resource = resource
        
        
        let latitude = resource.latitude ?? 0
        let longitude = resource.longitude ?? 0
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Map (if coordinates available)
                if resource.latitude != nil && resource.longitude != nil {
                    Map(coordinateRegion: $region, annotationItems: [resource]) { resource in
                        MapMarker(coordinate: CLLocationCoordinate2D(
                            latitude: resource.latitude!,
                            longitude: resource.longitude!
                        ))
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(resource.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(resource.description)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let phone = resource.phoneNumber {
                            DetailRow(icon: "phone.fill", text: phone) {
                                
                            }
                        }
                        
                        if let website = resource.website {
                            DetailRow(icon: "globe", text: website.absoluteString) {
                                
                            }
                        }
                        
                        if let address = resource.address {
                            DetailRow(icon: "location.fill", text: formatAddress(address)) {
                                
                            }
                        }
                        
                        if let hours = resource.hours {
                            DetailRow(icon: "clock.fill", text: hours)
                        }
                    }
                    
                    Divider()
                    
                    
                    Text("Services")
                        .font(.headline)
                    
                    ForEach(resource.services, id: \.self) { service in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.footnote)
                                .padding(.top, 3)
                            
                            Text(service)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(resource.type.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    private func formatAddress(_ address: Address) -> String {
        var formattedAddress = address.street1
        
        if let street2 = address.street2, !street2.isEmpty {
            formattedAddress += ", \(street2)"
        }
        
        formattedAddress += "\n\(address.city), \(address.state) \(address.postalCode)"
        
        return formattedAddress
    }
}


struct DetailRow: View {
    let icon: String
    let text: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
                .padding(.top, 2)
            
            if let action = action {
                Button(action: action) {
                    Text(text)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(text)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}


struct AbuseTypesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(abuseTypes, id: \.title) { abuseType in
                    AbuseTypeCard(abuseType: abuseType)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Remember")
                        .font(.headline)
                    
                    Text("• Abuse is NEVER your fault")
                    Text("• You deserve to be safe and treated with respect")
                    Text("• There are people who care and want to help")
                    Text("• Reporting abuse takes courage")
                    Text("• You are not alone in what you're experiencing")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Types of Abuse")
    }
    
    
    private let abuseTypes = [
        AbuseTypeInfo(
            title: "Physical Abuse",
            icon: "hand.raised.slash",
            color: .red,
            description: "Physical abuse is when someone hurts your body on purpose.",
            examples: [
                "Hitting, slapping, or punching",
                "Kicking or shoving",
                "Burning or cutting",
                "Choking or strangling",
                "Preventing basic needs like food, water, or sleep"
            ],
            warning: "If someone is physically hurting you, it's important to tell a trusted adult or contact emergency services if you're in immediate danger."
        ),
        AbuseTypeInfo(
            title: "Emotional Abuse",
            icon: "heart.slash",
            color: .purple,
            description: "Emotional abuse is when someone repeatedly says or does things to make you feel worthless, scared, or unloved.",
            examples: [
                "Constant criticism or insults",
                "Yelling and threats",
                "Humiliation or public embarrassment",
                "Ignoring you or giving 'silent treatment'",
                "Isolating you from friends or family",
                "Blaming you for everything"
            ],
            warning: "Emotional abuse can be hard to recognize but can cause serious harm to your mental health and well-being."
        ),
        AbuseTypeInfo(
            title: "Sexual Abuse",
            icon: "exclamationmark.shield",
            color: .orange,
            description: "Sexual abuse is any unwanted sexual contact or attention.",
            examples: [
                "Touching private parts without permission",
                "Forcing sexual acts",
                "Taking or sharing sexual photos or videos",
                "Making sexual comments or threats",
                "Showing private parts or pornography",
                "Pressuring you to do sexual things"
            ],
            warning: "No one has the right to touch you in a way that makes you uncomfortable. Your body belongs to you."
        ),
        AbuseTypeInfo(
            title: "Neglect",
            icon: "xmark.circle",
            color: .blue,
            description: "Neglect happens when a parent or caregiver doesn't provide basic needs that are necessary for your health, safety, and well-being.",
            examples: [
                "Not providing enough food or proper nutrition",
                "Unsafe or unclean living conditions",
                "Lack of medical or dental care when needed",
                "Not ensuring you attend school",
                "Leaving you alone for long periods when you're too young",
                "Not providing emotional support or attention"
            ],
            warning: "Everyone deserves to have their basic needs met. Neglect can have serious effects on your health and development."
        ),
        AbuseTypeInfo(
            title: "Bullying",
            icon: "person.2.slash",
            color: .green,
            description: "Bullying is when someone repeatedly uses words or actions to hurt, scare, or exclude you.",
            examples: [
                "Physical attacks like hitting or pushing",
                "Name-calling, teasing, or threats",
                "Spreading rumors or lies about you",
                "Excluding you from groups on purpose",
                "Cyberbullying through texts, social media, or online games"
            ],
            warning: "Bullying is never okay and is not your fault. You deserve to feel safe at school, online, and in your community."
        )
    ]
}


struct AbuseTypeInfo {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let examples: [String]
    let warning: String
}


struct AbuseTypeCard: View {
    let abuseType: AbuseTypeInfo
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Image(systemName: abuseType.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(abuseType.color)
                    .clipShape(Circle())
                
                Text(abuseType.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            
            Text(abuseType.description)
                .foregroundColor(.secondary)
            
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples:")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    ForEach(abuseType.examples, id: \.self) { example in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(abuseType.color)
                            Text(example)
                        }
                    }
                    
                    if !abuseType.warning.isEmpty {
                        Text(abuseType.warning)
                            .padding()
                            .font(.callout)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(abuseType.color.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


struct YourRightsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("As a child or teenager, you have important rights that are protected by law. Understanding these rights can help you recognize when they aren't being respected and give you the confidence to speak up.")
                    .padding(.bottom, 10)
                
                ForEach(rightsCategories, id: \.title) { category in
                    RightsCategoryCard(category: category)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standing Up For Your Rights")
                        .font(.headline)
                    
                    Text("If you believe your rights are being violated:")
                        .padding(.bottom, 4)
                    
                    Text("• Tell a trusted adult like a teacher, counselor, or relative")
                    Text("• Document what happened with dates and details")
                    Text("• Contact a youth advocacy organization or hotline")
                    Text("• In an emergency, call 911 or local emergency services")
                    
                    Text("Remember: Speaking up about rights violations takes courage. You deserve to be heard and protected.")
                        .padding(.top, 10)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Your Rights")
    }
    
    
    private let rightsCategories = [
        RightsCategory(
            title: "Safety Rights",
            icon: "shield.fill",
            color: .red,
            rights: [
                "You have the right to be protected from physical, emotional, and sexual abuse",
                "You have the right to basic needs: food, clothing, shelter, and healthcare",
                "You have the right to live in a safe environment free from danger",
                "You have the right to get help in dangerous situations"
            ]
        ),
        RightsCategory(
            title: "Educational Rights",
            icon: "book.fill",
            color: .blue,
            rights: [
                "You have the right to an education",
                "You have the right to a safe school environment free from bullying",
                "You have the right to accommodations if you have learning differences",
                "You have the right to participate in school activities"
            ]
        ),
        RightsCategory(
            title: "Healthcare Rights",
            icon: "heart.fill",
            color: .green,
            rights: [
                "You have the right to medical care when you're sick or injured",
                "You have the right to mental health support",
                "In many states, you have the right to certain healthcare services without parental consent",
                "You have the right to privacy regarding your medical information"
            ]
        ),
        RightsCategory(
            title: "Privacy Rights",
            icon: "hand.raised.fill",
            color: .purple,
            rights: [
                "You have the right to reasonable privacy, even as a minor",
                "You have the right to confidential conversations with counselors, doctors, and lawyers",
                "You have the right to report abuse without fear of retaliation",
                "You have the right to personal boundaries"
            ]
        ),
        RightsCategory(
            title: "Legal Rights",
            icon: "building.columns.fill",
            color: .indigo,
            rights: [
                "You have the right to legal representation in court proceedings",
                "You have the right to be heard in legal matters that affect you",
                "You have the right to protection under the law",
                "You have the right to be free from discrimination"
            ]
        )
    ]
}


struct RightsCategory {
    let title: String
    let icon: String
    let color: Color
    let rights: [String]
}


struct RightsCategoryCard: View {
    let category: RightsCategory
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(category.color)
                        .clipShape(Circle())
                    
                    Text(category.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(category.rights, id: \.self) { right in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(category.color)
                            Text(right)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, 10)
                .padding(.top, 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


struct SafetyPlanView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A safety plan is a personalized, practical plan that can help you avoid dangerous situations and know the best way to react when you're in danger.")
                    .padding(.bottom, 10)
                
                ForEach(safetySteps, id: \.title) { step in
                    SafetyStepCard(step: step)
                }
                
                
                VStack(alignment: .center, spacing: 12) {
                    Text("Ready to create your own safety plan?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        
                    }) {
                        Text("Create My Safety Plan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Text("Your safety plan is private and saved only on your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Safety Planning")
    }
    
    
    private let safetySteps = [
        SafetyStep(
            title: "Identify Warning Signs",
            icon: "exclamationmark.triangle",
            color: .orange,
            description: "Learn to recognize situations that might become dangerous before they escalate.",
            content: [
                "Pay attention to behaviors that have led to problems in the past",
                "Notice when someone's tone, body language, or words make you feel unsafe",
                "Be aware of circumstances that tend to trigger abuse (like alcohol use)",
                "Trust your instincts - if something feels wrong, it probably is"
            ]
        ),
        SafetyStep(
            title: "Know Your Safe Places",
            icon: "house.fill",
            color: .green,
            description: "Identify places you can go quickly if you feel threatened or need help.",
            content: [
                "Identify rooms with exits and locks where you can go in an emergency",
                "Know which neighbors, friends, or relatives you can go to for help",
                "Locate public places nearby (stores, libraries, fire stations) that are safe",
                "Avoid isolated areas where it would be hard for others to help you"
            ]
        ),
        SafetyStep(
            title: "Create a Support Network",
            icon: "person.3.fill",
            color: .blue,
            description: "Build a list of people you trust who can help in different situations.",
            content: [
                "Identify trusted adults you can talk to about your situation",
                "Memorize phone numbers of people who can help in an emergency",
                "Consider teachers, counselors, coaches, friends' parents, or relatives",
                "Identify which people to contact for different types of situations"
            ]
        ),
        SafetyStep(
            title: "Plan Emergency Communication",
            icon: "phone.fill",
            color: .red,
            description: "Have a plan for how to call for help quickly if you need it.",
            content: [
                "Practice calling 911 and know what information to provide",
                "Create a code word/phrase to alert friends or family you need help",
                "Know how to use your phone's emergency features",
                "Have backup methods to communicate if your phone is taken away"
            ]
        ),
        SafetyStep(
            title: "Prepare an Emergency Bag",
            icon: "bag.fill",
            color: .purple,
            description: "If you might need to leave quickly, having essential items ready can help.",
            content: [
                "Keep important documents accessible (ID, birth certificate, etc.)",
                "Have some money hidden for emergency transportation",
                "Pack a change of clothes and essential toiletries",
                "Include important medications and a list of phone numbers"
            ]
        )
    ]
}


struct SafetyStep {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let content: [String]
}


struct SafetyStepCard: View {
    let step: SafetyStep
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: step.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(step.color)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(step.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(step.content, id: \.self) { item in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(step.color)
                            Text(item)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, 10)
                .padding(.top, 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


struct ResourceFinderView: View {
    @State private var searchQuery = ""
    @State private var selectedResourceType: Resource.ResourceType?
    @State private var searchRadius: Double = 25
    @State private var showingLocationPrompt = false
    @State private var isSearching = false
    @StateObject private var viewModel = ResourceFinderViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 16) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name or keyword", text: $searchQuery)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.searchResources(query: searchQuery, type: selectedResourceType, radius: Int(searchRadius))
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                
                HStack {
                    
                    Menu {
                        Button("All Types") {
                            selectedResourceType = nil
                        }
                        
                        Divider()
                        
                        ForEach(Resource.ResourceType.allCases, id: \.self) { type in
                            Button(type.displayName) {
                                selectedResourceType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedResourceType?.displayName ?? "All Types")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Within \(Int(searchRadius)) miles")
                            .font(.caption)
                        
                        Slider(value: $searchRadius, in: 5...100, step: 5)
                            .frame(width: 150)
                    }
                }
                
                
                Button(action: {
                    showingLocationPrompt = true
                    
                    viewModel.searchResources(query: searchQuery, type: selectedResourceType, radius: Int(searchRadius))
                }) {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                        Text("Find Near Me")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Searching for resources...")
                    Spacer()
                }
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.hasSearched ? "No resources found matching your criteria" : "Search for resources near you")
                        .font(.headline)
                    
                    if viewModel.hasSearched {
                        Text("Try adjusting your search distance or filters")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.searchResults) { resource in
                        NavigationLink(destination: ResourceDetailView(resource: resource)) {
                            ResourceSearchResultRow(resource: resource)
                        }
                    }
                }
            }
        }
        .navigationTitle("Find Resources")
        .alert("Location Access", isPresented: $showingLocationPrompt) {
            Button("Allow") {
                
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app needs your location to find nearby resources. Your location is not stored or shared.")
        }
    }
}


extension Resource.ResourceType {
    static var allCases: [Resource.ResourceType] {
        return [.shelter, .counseling, .legalAid, .childServices, .hotline, .medical, .police, .school, .other]
    }
    
    var displayName: String {
        switch self {
        case .shelter: return "Shelter"
        case .counseling: return "Counseling"
        case .legalAid: return "Legal Aid"
        case .childServices: return "Child Services"
        case .hotline: return "Hotline"
        case .medical: return "Medical"
        case .police: return "Police"
        case .school: return "School"
        case .other: return "Other"
        }
    }
}


class ResourceFinderViewModel: ObservableObject {
    @Published var searchResults: [Resource] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    
    func searchResources(query: String, type: Resource.ResourceType?, radius: Int) {
        
        isLoading = true
        hasSearched = true
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            
            let sampleResults = self.generateSampleResults(query: query, type: type)
            
            self.searchResults = sampleResults
            self.isLoading = false
        }
    }
    
    
    private func generateSampleResults(query: String, type: Resource.ResourceType?) -> [Resource] {
        let allResults = [
            Resource(
                id: "1",
                name: "Youth Crisis Center",
                type: .shelter,
                description: "Emergency shelter and counseling for youth",
                phoneNumber: "555-123-4567",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "123 Main St",
                    street2: nil,
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "24/7",
                services: ["Emergency shelter", "Counseling", "Family mediation"],
                emergencyService: true,
                latitude: 34.0522,
                longitude: -118.2437,
                distance: 3.5
            ),
            Resource(
                id: "2",
                name: "Teen Counseling Services",
                type: .counseling,
                description: "Free counseling for teens and families",
                phoneNumber: "555-987-6543",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "456 Oak Ave",
                    street2: "Suite 200",
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Fri 9am-7pm",
                services: ["Individual counseling", "Group therapy", "Crisis intervention"],
                emergencyService: false,
                latitude: 34.0530,
                longitude: -118.2445,
                distance: 4.2
            ),
            Resource(
                id: "3",
                name: "Children's Legal Aid",
                type: .legalAid,
                description: "Legal assistance for children and teens",
                phoneNumber: "555-456-7890",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "789 Pine St",
                    street2: nil,
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Fri 9am-5pm",
                services: ["Legal advice", "Court representation", "Advocacy"],
                emergencyService: false,
                latitude: 34.0515,
                longitude: -118.2430,
                distance: 2.8
            ),
            Resource(
                id: "4",
                name: "Child Protection Services",
                type: .childServices,
                description: "Government agency for child welfare",
                phoneNumber: "555-789-0123",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "1000 Government Ave",
                    street2: "Floor 3",
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Fri 8am-5pm",
                services: ["Child abuse investigation", "Family services", "Foster care coordination"],
                emergencyService: true,
                latitude: 34.0500,
                longitude: -118.2400,
                distance: 5.1
            ),
            Resource(
                id: "5",
                name: "Safe Harbor Medical Clinic",
                type: .medical,
                description: "Confidential healthcare for youth",
                phoneNumber: "555-321-6547",
                website: URL(string: "https://example.org"),
                address: Address(
                    street1: "222 Health Blvd",
                    street2: nil,
                    city: "Anytown",
                    state: "CA",
                    postalCode: "90210",
                    country: "USA"
                ),
                hours: "Mon-Sat 9am-6pm",
                services: ["General healthcare", "STI testing", "Mental health", "Confidential services"],
                emergencyService: false,
                latitude: 34.0540,
                longitude: -118.2450,
                distance: 3.9
            )
        ]
        
        
        var filteredResults = allResults
        
        if let type = type {
            filteredResults = filteredResults.filter { $0.type == type }
        }
        
        if !query.isEmpty {
            filteredResults = filteredResults.filter { 
                $0.name.lowercased().contains(query.lowercased()) || 
                $0.description.lowercased().contains(query.lowercased()) ||
                $0.services.joined(separator: " ").lowercased().contains(query.lowercased())
            }
        }
        
        return filteredResults.sorted { $0.distance ?? 100 < $1.distance ?? 100 }
    }
}


struct ResourceSearchResultRow: View {
    let resource: Resource
    
    var body: some View {
        HStack(spacing: 15) {
            // Resource type icon
            Image(systemName: iconForResourceType(resource.type))
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(colorForResourceType(resource.type))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.name)
                    .font(.headline)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 15) {
                    
                    if let distance = resource.distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text("\(String(format: "%.1f", distance)) mi")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    
                    if let hours = resource.hours {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(hours)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    
                    if resource.emergencyService {
                        Text("24/7")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    
    private func iconForResourceType(_ type: Resource.ResourceType) -> String {
        switch type {
        case .shelter: return "house.fill"
        case .counseling: return "person.fill.questionmark"
        case .legalAid: return "building.columns.fill"
        case .childServices: return "person.3.fill"
        case .hotline: return "phone.fill"
        case .medical: return "cross.fill"
        case .police: return "shield.fill"
        case .school: return "book.fill"
        case .other: return "info.circle"
        }
    }
    
    
    private func colorForResourceType(_ type: Resource.ResourceType) -> Color {
        switch type {
        case .shelter: return .indigo
        case .counseling: return .purple
        case .legalAid: return .blue
        case .childServices: return .green
        case .hotline: return .red
        case .medical: return .red
        case .police: return .blue
        case .school: return .orange
        case .other: return .gray
        }
    }
}
