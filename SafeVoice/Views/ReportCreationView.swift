//
//  ReportCreationView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI
import PhotosUI
import CoreLocation

struct ReportCreationView: View {
    @EnvironmentObject var reportStore: ReportStore
    @StateObject var viewModel = ReportCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    
    var report: Report?
    var isEditingDraft: Bool = false
    
    init(report: Report? = nil, isEditingDraft: Bool = false) {
        self.report = report
        self.isEditingDraft = isEditingDraft
    }
    
    var body: some View {
        Form {
            
            Section(header: Text("What are you reporting?")) {
                Picker("Type", selection: $viewModel.reportType) {
                    ForEach(viewModel.reportTypes, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                if viewModel.reportType == .other {
                    TextField("Please specify", text: $viewModel.otherTypeDetails)
                }
                
                HStack {
                    Text("Learn more about types of abuse")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .onTapGesture {
                    viewModel.showingResourceInfo = true
                }
            }
            
            
            Section(header: Text("What happened?")) {
                TextEditor(text: $viewModel.reportContent)
                    .frame(minHeight: 150)
                
                if viewModel.reportContent.isEmpty {
                    Text("You can describe what happened here. Include details that might help someone understand your situation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            
            
            Section(header: Text("Add photos (optional)")) {
                if !viewModel.selectedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(0..<viewModel.selectedImages.count, id: \.self) { index in
                                Image(uiImage: viewModel.selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            Button(action: {
                                                viewModel.removeImage(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                            }
                                            .padding(4),
                                            alignment: .topTrailing
                                        )
                                        .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                Button(action: {
                    viewModel.showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Add Photo")
                    }
                }
            }
            
            
            Section(header: Text("Privacy Options")) {
                Toggle("Submit anonymously", isOn: $viewModel.isAnonymous)
                
                if !viewModel.isAnonymous {
                    TextField("Your name (optional)", text: $viewModel.contactName)
                    TextField("Contact email (optional)", text: $viewModel.contactEmail)
                        .keyboardType(.emailAddress)
                    
                    Text("Your contact information will only be used by support staff to follow up on your report if needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            
            Section {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Need to exit quickly?")
                    Spacer()
                    Button("Quick Exit") {
                        // Exit to disguise mode
                        viewModel.activateEmergencyExit()
                    }
                    .foregroundColor(.red)
                }
            }
            
            
            Section {
                Button(action: {
                    if isEditingDraft {
                        submitReport()
                    } else {
                        submitReport()
                    }
                }) {
                    Text(isEditingDraft ? "Submit Report" : "Submit Report")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .disabled(!viewModel.canSubmit)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(isEditingDraft ? "Edit Report" : "New Report")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveDraft()
                }) {
                    Text("Save Draft")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImages: $viewModel.selectedImages)
        }
        .sheet(isPresented: $viewModel.showingResourceInfo) {
            ResourceInfoView()
        }
        .alert("Report Submitted", isPresented: $viewModel.showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. A specialist will review it and take appropriate action.")
        }
        .alert("Draft Saved", isPresented: $viewModel.showingDraftSaved) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your report has been saved as a draft. You can complete and submit it later.")
        }
        .alert(isPresented: $viewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if let existingReport = report {
                viewModel.loadExistingReport(existingReport)
            }
        }
    }
    
    
    func submitReport() {
        
        var reportToSubmit = Report(
            id: viewModel.editingReportID ?? "",
            timestamp: Date(),
            reportType: viewModel.reportType,
            content: viewModel.reportContent,
            isAnonymous: viewModel.isAnonymous
        )
        
        // Add contact info if not anonymous
        if !viewModel.isAnonymous {
            reportToSubmit.contactInfo = ContactInfo(
                name: viewModel.contactName,
                email: viewModel.contactEmail,
                phone: nil,
                preferredContactMethod: !viewModel.contactEmail.isEmpty ? .email : .none
            )
        }
        
        
        
        
        
        if let location = viewModel.currentLocation {
            reportToSubmit.locationData = LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: Date()
            )
        }
        
        
        reportStore.submitReport(reportToSubmit) { result in
            switch result {
            case .success(_):
                viewModel.showingConfirmation = true
                viewModel.resetForm()
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
                viewModel.showingError = true
            }
        }
    }
    
    
    func saveDraft() {
        
        let draftReport = Report(
            id: viewModel.editingReportID ?? "",
            timestamp: Date(),
            reportType: viewModel.reportType,
            content: viewModel.reportContent,
            isAnonymous: viewModel.isAnonymous,
            status: .drafted
        )
        
        
        reportStore.saveDraft(draftReport)
        viewModel.showingDraftSaved = true
    }
}


class ReportCreationViewModel: ObservableObject {
    
    @Published var reportType: Report.ReportType = .other
    @Published var otherTypeDetails: String = ""
    @Published var reportContent: String = ""
    @Published var isAnonymous: Bool = true
    @Published var contactName: String = ""
    @Published var contactEmail: String = ""
    
    
    @Published var showingImagePicker = false
    @Published var showingResourceInfo = false
    @Published var showingConfirmation = false
    @Published var showingDraftSaved = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isDraftSaved = false
    
    
    @Published var selectedImages: [UIImage] = []
    
    
    @Published var currentLocation: CLLocation?
    
    
    @Published var editingReportID: String?
    
    
    let reportTypes = Report.ReportType.allCases
    
    
    var canSubmit: Bool {
        !reportContent.isEmpty
    }
    
    
    func loadExistingReport(_ report: Report) {
        editingReportID = report.id
        reportType = report.reportType
        reportContent = report.content
        isAnonymous = report.isAnonymous
        
        
        if let contactInfo = report.contactInfo {
            contactName = contactInfo.name ?? ""
            contactEmail = contactInfo.email ?? ""
        }
        
        
        if let locationData = report.locationData {
            currentLocation = CLLocation(
                latitude: locationData.latitude,
                longitude: locationData.longitude
            )
        }
        
        
    }
    
    
    func resetForm() {
        reportType = .other
        otherTypeDetails = ""
        reportContent = ""
        isAnonymous = true
        contactName = ""
        contactEmail = ""
        selectedImages = []
        editingReportID = nil
    }
    
    
    func removeImage(at index: Int) {
        if index < selectedImages.count {
            selectedImages.remove(at: index)
        }
    }
    
    
    func activateEmergencyExit() {
        
        
        NotificationCenter.default.post(name: NSNotification.Name("ActivateEmergencyExit"), object: nil)
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 5
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct ResourceInfoView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Physical Abuse")) {
                    Text("Physical abuse involves physical harm or injury to a child. This can include hitting, shaking, burning, or other actions that result in physical injury.")
                }
                
                Section(header: Text("Emotional/Verbal Abuse")) {
                    Text("Emotional abuse involves behaviors that harm a child's self-worth or emotional well-being. This includes name calling, shaming, rejection, withholding love, and threatening.")
                }
                
                Section(header: Text("Neglect")) {
                    Text("Neglect is the failure to provide for a child's basic needs. This includes adequate food, clothing, shelter, supervision, medical care, education, or emotional nurturing.")
                }
                
                Section(header: Text("Sexual Abuse")) {
                    Text("Sexual abuse includes engaging a child in sexual acts, exposing children to sexual content, or inappropriate touching. It also includes exploitation through photography or video.")
                }
                
                Section(header: Text("Bullying")) {
                    Text("Bullying is unwanted aggressive behavior that involves a power imbalance. It includes threats, spreading rumors, physical or verbal attacks, and exclusion from groups.")
                }
            }
            .navigationTitle("Types of Abuse")
        }
    }
}
