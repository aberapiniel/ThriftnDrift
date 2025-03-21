import SwiftUI
import MapKit

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedSubmission: Store?
    @State private var showingRejectionDialog = false
    @State private var rejectionReason = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(viewModel.pendingSubmissions) { submission in
                        SubmissionRow(submission: submission) {
                            selectedSubmission = submission
                        }
                    }
                } header: {
                    Text("Pending Submissions (\(viewModel.pendingSubmissions.count))")
                }
                
                Section {
                    ForEach(viewModel.recentlyApproved) { store in
                        StoreRow(store: store)
                    }
                } header: {
                    Text("Recently Approved (\(viewModel.recentlyApproved.count))")
                }
            }
            .navigationTitle("Admin Dashboard")
            .refreshable {
                await viewModel.loadSubmissions()
            }
            .sheet(item: $selectedSubmission) { submission in
                SubmissionDetailView(
                    submission: submission,
                    onApprove: {
                        Task {
                            do {
                                try await viewModel.approveSubmission(submission.id)
                                selectedSubmission = nil
                                alertMessage = "Store approved successfully"
                                showingAlert = true
                            } catch {
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                        }
                    },
                    onReject: {
                        selectedSubmission = submission
                        showingRejectionDialog = true
                    }
                )
            }
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Reject Submission", isPresented: $showingRejectionDialog) {
                TextField("Reason for rejection", text: $rejectionReason)
                Button("Cancel", role: .cancel) {
                    rejectionReason = ""
                }
                Button("Reject", role: .destructive) {
                    guard let submission = selectedSubmission else { return }
                    Task {
                        do {
                            try await viewModel.rejectSubmission(submission.id, reason: rejectionReason)
                            selectedSubmission = nil
                            rejectionReason = ""
                            alertMessage = "Store submission rejected"
                            showingAlert = true
                        } catch {
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        }
                    }
                }
            } message: {
                Text("Please provide a reason for rejecting this submission")
            }
        }
    }
}

struct SubmissionRow: View {
    let submission: Store
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.name)
                    .font(.headline)
                Text(submission.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Submitted: \(submission.lastVerified?.formatted() ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct SubmissionDetailView: View {
    let submission: Store
    let onApprove: () -> Void
    let onReject: () -> Void
    @State private var region: MKCoordinateRegion
    
    init(submission: Store, onApprove: @escaping () -> Void, onReject: @escaping () -> Void) {
        self.submission = submission
        self.onApprove = onApprove
        self.onReject = onReject
        
        _region = State(initialValue: MKCoordinateRegion(
            center: submission.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Map
                    Map(coordinateRegion: $region, annotationItems: [submission]) { store in
                        MapMarker(coordinate: store.coordinate)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    // Store Details
                    Group {
                        Text(submission.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(submission.address)
                            .foregroundColor(.secondary)
                        
                        if !submission.description.isEmpty {
                            Text(submission.description)
                                .padding(.top, 8)
                        }
                        
                        // Categories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(submission.categories, id: \.self) { category in
                                    Text(category)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Store Features
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Store Features")
                                .font(.headline)
                            
                            FeatureRow(title: "Accepts Donations", isEnabled: submission.acceptsDonations)
                            FeatureRow(title: "Clothing Section", isEnabled: submission.hasClothingSection)
                            FeatureRow(title: "Furniture Section", isEnabled: submission.hasFurnitureSection)
                            FeatureRow(title: "Electronics Section", isEnabled: submission.hasElectronicsSection)
                        }
                        .padding(.top, 8)
                        
                        // Contact Information
                        if submission.phoneNumber != nil || submission.website != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contact Information")
                                    .font(.headline)
                                
                                if let phone = submission.phoneNumber {
                                    Text("📞 \(phone)")
                                }
                                
                                if let website = submission.website {
                                    Text("🌐 \(website)")
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Review Submission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: onApprove) {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: onReject) {
                            Label("Reject", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? .green : .gray)
            Text(title)
        }
    }
} 