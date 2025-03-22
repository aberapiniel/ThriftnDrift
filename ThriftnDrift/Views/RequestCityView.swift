import SwiftUI

struct RequestCityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cityRequestService = CityRequestService.shared
    
    @State private var city = ""
    @State private var state = "NC"
    @State private var notes = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    private let states = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("City Information").foregroundColor(ThemeManager.textColor)) {
                    TextField("City Name", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(ThemeManager.textColor)
                        .autocapitalization(.words)
                    
                    Picker("State", selection: $state) {
                        ForEach(states, id: \.self) { state in
                            Text(state)
                                .foregroundColor(ThemeManager.textColor)
                                .tag(state)
                        }
                    }
                    .tint(ThemeManager.brandPurple)
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                
                Section(header: Text("Additional Information").foregroundColor(ThemeManager.textColor)) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .foregroundColor(ThemeManager.textColor)
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                
                if !cityRequestService.userRequests.isEmpty {
                    Section(header: Text("Your Requests").foregroundColor(ThemeManager.textColor)) {
                        ForEach(cityRequestService.userRequests) { request in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(request.city), \(request.state)")
                                        .font(.headline)
                                        .foregroundColor(ThemeManager.textColor)
                                    Text(request.status.capitalized)
                                        .font(.caption)
                                        .foregroundColor(statusColor(request.status))
                                }
                                
                                Spacer()
                                
                                if request.status == "pending" {
                                    Button(action: {
                                        cancelRequest(request)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("Request City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitRequest()
                    }
                    .foregroundColor(isValid ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.3))
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your request has been submitted. We'll notify you when stores in \(city) are available.")
            }
            .overlay {
                if isLoading {
                    ZStack {
                        ThemeManager.warmOverlay.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(ThemeManager.brandPurple)
                    }
                }
            }
        }
    }
    
    private var isValid: Bool {
        !city.isEmpty
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending":
            return .orange
        case "approved":
            return ThemeManager.brandPurple
        case "completed":
            return ThemeManager.brandPurple
        case "rejected":
            return .red
        default:
            return ThemeManager.textColor.opacity(0.7)
        }
    }
    
    private func submitRequest() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await cityRequestService.submitRequest(
                    city: city,
                    state: state,
                    notes: notes.isEmpty ? nil : notes
                )
                showingSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func cancelRequest(_ request: CityRequest) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await cityRequestService.cancelRequest(request.id)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
} 