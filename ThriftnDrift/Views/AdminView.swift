import SwiftUI
import MapKit

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubmission: Store?
    @State private var selectedPhotoSubmission: PhotoSubmission?
    @State private var showingRejectionDialog = false
    @State private var rejectionReason = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            ThemeManager.backgroundStyle
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Admin Dashboard")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(ThemeManager.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                Picker("Admin Section", selection: $selectedTab) {
                    Text("Submissions").tag(0)
                    Text("Photos").tag(1)
                    Text("Cities").tag(2)
                    Text("Admins").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(ThemeManager.warmOverlay.opacity(0.1))
                
                switch selectedTab {
                case 0:
                    submissionsView
                case 1:
                    photoSubmissionsView
                case 2:
                    cityRequestsView
                default:
                    AdminManagementView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Settings")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
            }
        }
    }
    
    private var submissionsView: some View {
        List {
            Section {
                ForEach(viewModel.pendingSubmissions) { submission in
                    SubmissionRow(submission: submission) {
                        selectedSubmission = submission
                    }
                }
            } header: {
                Text("Pending Submissions (\(viewModel.pendingSubmissions.count))")
                    .foregroundColor(ThemeManager.brandPurple)
            }
            
            Section {
                ForEach(viewModel.recentlyApproved) { store in
                    VStack(alignment: .leading) {
                        Text(store.name)
                            .font(.headline)
                            .foregroundColor(ThemeManager.textColor)
                        Text("Approved")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                }
            } header: {
                Text("Recently Approved")
                    .foregroundColor(ThemeManager.brandPurple)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .refreshable {
            await viewModel.loadSubmissions()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $selectedSubmission) { submission in
            SubmissionDetailView(
                submission: submission,
                onApprove: {
                    Task {
                        do {
                            try await viewModel.approveSubmission(submission.id)
                            selectedSubmission = nil
                        } catch {
                            showingAlert = true
                            alertMessage = error.localizedDescription
                        }
                    }
                },
                onReject: { reason in
                    Task {
                        do {
                            try await viewModel.rejectSubmission(submission.id, reason: reason)
                            selectedSubmission = nil
                        } catch {
                            showingAlert = true
                            alertMessage = error.localizedDescription
                        }
                    }
                }
            )
        }
    }
    
    private var photoSubmissionsView: some View {
        List {
            Section {
                if viewModel.pendingPhotoSubmissions.isEmpty {
                    Text("No pending photo submissions")
                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                        .italic()
                } else {
                    ForEach(viewModel.pendingPhotoSubmissions) { submission in
                        PhotoSubmissionRow(submission: submission) {
                            selectedPhotoSubmission = submission
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                }
            } header: {
                Text("Pending Photo Submissions (\(viewModel.pendingPhotoSubmissions.count))")
                    .foregroundColor(ThemeManager.brandPurple)
            }
            
            if !viewModel.recentlyApprovedPhotos.isEmpty {
                Section {
                    ForEach(groupPhotosByDate(viewModel.recentlyApprovedPhotos), id: \.date) { group in
                        DisclosureGroup(
                            content: {
                                ForEach(group.submissions) { submission in
                                    ApprovedPhotoRow(submission: submission)
                                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                                }
                            },
                            label: {
                                HStack {
                                    Text(formatDate(group.date))
                                        .font(.subheadline)
                                        .foregroundColor(ThemeManager.textColor)
                                    Spacer()
                                    Text("\(group.submissions.count) photos")
                                        .font(.caption)
                                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                                }
                            }
                        )
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                } header: {
                    Text("Recently Approved")
                        .foregroundColor(ThemeManager.brandPurple)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .refreshable {
            await viewModel.loadSubmissions()
        }
        .sheet(item: $selectedPhotoSubmission) { submission in
            PhotoSubmissionDetailView(
                submission: submission,
                onApprove: {
                    Task {
                        do {
                            try await viewModel.approvePhotoSubmission(submission)
                            selectedPhotoSubmission = nil
                        } catch {
                            showingAlert = true
                            alertMessage = error.localizedDescription
                        }
                    }
                },
                onReject: {
                    Task {
                        do {
                            try await viewModel.rejectPhotoSubmission(submission)
                            selectedPhotoSubmission = nil
                        } catch {
                            showingAlert = true
                            alertMessage = error.localizedDescription
                        }
                    }
                }
            )
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var cityRequestsView: some View {
        List {
            if viewModel.pendingCityRequests.isEmpty {
                Text("No pending city requests")
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                    .padding()
            } else {
                Section {
                    ForEach(viewModel.pendingCityRequests) { request in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(request.city), \(request.state)")
                                .font(.headline)
                                .foregroundColor(ThemeManager.textColor)
                            Text("Requested: \(request.requestedAt.formatted())")
                                .font(.caption)
                                .foregroundColor(ThemeManager.textColor.opacity(0.6))
                            if let notes = request.notes {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(ThemeManager.textColor.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await viewModel.rejectCityRequest(request.id)
                                    } catch {
                                        showingAlert = true
                                        alertMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Reject", systemImage: "xmark.circle.fill")
                            }
                            
                            Button {
                                Task {
                                    do {
                                        try await viewModel.completeCityRequest(request.id)
                                    } catch {
                                        showingAlert = true
                                        alertMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                    }
                } header: {
                    Text("Pending City Requests")
                        .foregroundColor(ThemeManager.brandPurple)
                }
            }
            
            if !viewModel.recentlyCompletedCityRequests.isEmpty {
                Section {
                    ForEach(viewModel.recentlyCompletedCityRequests) { request in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(request.city), \(request.state)")
                                .font(.headline)
                                .foregroundColor(ThemeManager.textColor)
                            Text("Status: \(request.status.capitalized)")
                                .font(.caption)
                                .foregroundColor(request.status == "completed" ? .green : .red)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                } header: {
                    Text("Recently Processed")
                        .foregroundColor(ThemeManager.brandPurple)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .refreshable {
            await viewModel.loadCityRequests()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadCityRequests()
            }
        }
    }
    
    // Helper struct for grouping photos by date
    private struct PhotoGroup {
        let date: Date
        let submissions: [PhotoSubmission]
    }
    
    // Helper function to group photos by date
    private func groupPhotosByDate(_ photos: [PhotoSubmission]) -> [PhotoGroup] {
        let grouped = Dictionary(grouping: photos) { submission in
            Calendar.current.startOfDay(for: submission.reviewedAt ?? submission.submittedAt)
        }
        
        return grouped.map { PhotoGroup(date: $0.key, submissions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct AdminManagementView: View {
    @StateObject private var viewModel = AdminManagementViewModel()
    @State private var showingAddAdmin = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section {
                if viewModel.admins.isEmpty {
                    Text("No admins found")
                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                        .italic()
                } else {
                    ForEach(viewModel.admins) { admin in
                        AdminRow(admin: admin) {
                            Task {
                                do {
                                    try await viewModel.removeAdmin(admin.id)
                                } catch {
                                    showingAlert = true
                                    alertMessage = error.localizedDescription
                                }
                            }
                        }
                        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                    }
                }
            } header: {
                HStack {
                    Text("Current Admins")
                        .foregroundColor(ThemeManager.brandPurple)
                    Spacer()
                    Button(action: { showingAddAdmin = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(ThemeManager.brandPurple)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThemeManager.backgroundStyle)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingAddAdmin) {
            AddAdminView { email in
                Task {
                    do {
                        try await viewModel.addAdmin(email: email)
                        showingAddAdmin = false
                    } catch {
                        showingAlert = true
                        alertMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct AdminRow: View {
    let admin: Admin
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(admin.email)
                    .font(.headline)
                    .foregroundColor(ThemeManager.brandPurple)
                Text("User ID: \(admin.userId)")
                    .font(.caption)
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                Text("Added by: \(admin.grantedByEmail)")
                    .font(.caption)
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                Text("Role: \(admin.role)")
                    .font(.caption)
                    .foregroundColor(ThemeManager.brandPurple)
            }
            .allowsHitTesting(false)
            
            Spacer()
                .allowsHitTesting(false)
            
            Button(action: onRemove) {
                Image(systemName: "person.fill.xmark")
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct AddAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.backgroundStyle
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .accentColor(ThemeManager.brandPurple)
                            .foregroundColor(ThemeManager.textColor)
                    } header: {
                        Text("New Admin Details")
                            .foregroundColor(ThemeManager.brandPurple)
                    } footer: {
                        Text("Enter the email address of the user you want to make an admin.")
                            .foregroundColor(ThemeManager.textColor.opacity(0.6))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ThemeManager.brandPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(email)
                    }
                    .disabled(email.isEmpty)
                    .foregroundColor(email.isEmpty ? ThemeManager.textColor.opacity(0.4) : ThemeManager.brandPurple)
                }
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
                    .foregroundColor(ThemeManager.textColor)
                Text(submission.address)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                Text("Submitted: \(submission.lastVerified?.formatted() ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
    }
}

struct SubmissionDetailView: View {
    let submission: Store
    let onApprove: () -> Void
    let onReject: (String) -> Void
    @State private var region: MKCoordinateRegion
    @State private var rejectionReason = ""
    @State private var showingRejectionAlert = false
    
    init(submission: Store, onApprove: @escaping () -> Void, onReject: @escaping (String) -> Void) {
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
                        
                        Button(action: { showingRejectionAlert = true }) {
                            Label("Reject", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Reject Submission", isPresented: $showingRejectionAlert) {
                TextField("Reason for rejection", text: $rejectionReason)
                Button("Cancel", role: .cancel) {
                    rejectionReason = ""
                }
                Button("Reject", role: .destructive) {
                    onReject(rejectionReason)
                    rejectionReason = ""
                }
            } message: {
                Text("Please provide a reason for rejecting this submission")
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

struct PhotoSubmissionRow: View {
    let submission: PhotoSubmission
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let firstImageUrl = submission.imageUrls.first {
                    AsyncImage(url: URL(string: firstImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ThemeManager.warmOverlay.opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.storeName)
                        .font(.headline)
                        .foregroundColor(ThemeManager.brandPurple)
                    Text("\(submission.imageUrls.count) photos")
                        .font(.subheadline)
                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                    Text("Submitted: \(submission.submittedAt.formatted())")
                        .font(.caption)
                        .foregroundColor(ThemeManager.textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(ThemeManager.textColor.opacity(0.4))
            }
            .padding(.vertical, 4)
        }
    }
}

struct ApprovedPhotoRow: View {
    let submission: PhotoSubmission
    
    var body: some View {
        HStack {
            if let firstImageUrl = submission.imageUrls.first {
                AsyncImage(url: URL(string: firstImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ThemeManager.warmOverlay.opacity(0.2)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.storeName)
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.brandPurple)
                Text("\(submission.imageUrls.count) photos")
                    .font(.caption)
                    .foregroundColor(ThemeManager.textColor.opacity(0.6))
                if let reviewedAt = submission.reviewedAt {
                    Text("Approved: \(reviewedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}