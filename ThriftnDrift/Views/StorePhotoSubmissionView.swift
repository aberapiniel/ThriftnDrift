import SwiftUI
import PhotosUI

struct StorePhotoSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    let store: Store
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var displayedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Store Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.textColor)
                        Text(store.address)
                            .font(.subheadline)
                            .foregroundColor(ThemeManager.textColor.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    
                    // Photos Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Add Photos")
                                .font(.headline)
                                .foregroundColor(ThemeManager.textColor)
                            Spacer()
                            Text("\(displayedImages.count)/5")
                                .foregroundColor(ThemeManager.textColor.opacity(0.7))
                        }
                        .padding(.horizontal, 24)
                        
                        if displayedImages.isEmpty {
                            PhotosPicker(selection: $selectedPhotos,
                                       maxSelectionCount: 5,
                                       matching: .images) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 40))
                                        .foregroundColor(ThemeManager.brandPurple)
                                    Text("Select Photos")
                                        .foregroundColor(ThemeManager.brandPurple)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(ThemeManager.warmOverlay.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if !displayedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(displayedImages.indices, id: \.self) { index in
                                        VStack {
                                            Image(uiImage: displayedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(ThemeManager.warmOverlay.opacity(0.2), lineWidth: 1)
                                                )
                                                .overlay(
                                                    Button(action: {
                                                        withAnimation {
                                                            if index < displayedImages.count && index < selectedPhotos.count {
                                                                displayedImages.remove(at: index)
                                                                selectedPhotos.remove(at: index)
                                                            }
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(ThemeManager.warmOverlay)
                                                            .font(.system(size: 22))
                                                            .background(Circle().fill(ThemeManager.textColor))
                                                            .padding(8)
                                                    }
                                                    .buttonStyle(PlainButtonStyle()),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                    
                                    if displayedImages.count < 5 {
                                        PhotosPicker(selection: $selectedPhotos,
                                                   maxSelectionCount: 5,
                                                   matching: .images) {
                                            VStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 32))
                                                Text("Add More")
                                                    .font(.subheadline)
                                            }
                                            .foregroundColor(ThemeManager.brandPurple)
                                            .frame(width: 120, height: 120)
                                            .background(ThemeManager.warmOverlay.opacity(0.1))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // Guidelines Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Photo Guidelines")
                            .font(.headline)
                            .foregroundColor(ThemeManager.textColor)
                        
                        GuidelineRow(icon: "checkmark.circle.fill", text: "Clear, well-lit photos", isPositive: true)
                        GuidelineRow(icon: "checkmark.circle.fill", text: "Store front or interior", isPositive: true)
                        GuidelineRow(icon: "checkmark.circle.fill", text: "No people in photos", isPositive: true)
                        GuidelineRow(icon: "xmark.circle.fill", text: "No blurry or dark images", isPositive: false)
                        GuidelineRow(icon: "xmark.circle.fill", text: "No inappropriate content", isPositive: false)
                    }
                    .padding(20)
                    .background(ThemeManager.warmOverlay.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 16)
            }
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("Submit Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitPhotos) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(ThemeManager.brandPurple)
                        } else {
                            Text("Submit")
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(displayedImages.isEmpty || isSubmitting)
                    .foregroundColor(displayedImages.isEmpty || isSubmitting ? 
                        ThemeManager.brandPurple.opacity(0.5) : ThemeManager.brandPurple)
                }
            }
            .onChange(of: selectedPhotos) { _ in
                Task {
                    await loadImages()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    if errorMessage.contains("All images were duplicates") {
                        dismiss()
                    }
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Photos submitted successfully!")
            }
        }
    }
    
    private func loadImages() async {
        var newImages: [UIImage] = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if !displayedImages.contains(where: { $0.pngData() == image.pngData() }) {
                    newImages.append(image)
                }
            }
        }
        
        await MainActor.run {
            displayedImages.append(contentsOf: newImages)
            if displayedImages.count > 5 {
                displayedImages = Array(displayedImages.prefix(5))
                selectedPhotos = Array(selectedPhotos.prefix(5))
            }
        }
    }
    
    private func submitPhotos() {
        guard !displayedImages.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await StoreService.shared.submitStorePhotos(storeId: store.id, images: displayedImages)
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct GuidelineRow: View {
    let icon: String
    let text: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isPositive ? ThemeManager.brandPurple : .red)
            Text(text)
                .font(.subheadline)
                .foregroundColor(ThemeManager.textColor)
        }
    }
} 
