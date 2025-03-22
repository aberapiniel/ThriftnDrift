import SwiftUI
import PhotosUI

struct StorePhotoSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    let store: Store
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var displayedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Store Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(store.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Photos Section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Add Photos")
                                .font(.headline)
                            Spacer()
                            Text("\(displayedImages.count)/5")
                                .foregroundColor(.gray)
                        }
                        
                        if displayedImages.isEmpty {
                            PhotosPicker(selection: $selectedPhotos,
                                       maxSelectionCount: 5,
                                       matching: .images) {
                                VStack {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 40))
                                        .foregroundColor(themeColor)
                                    Text("Select Photos")
                                        .foregroundColor(themeColor)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(themeColor.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
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
                                                    .stroke(themeColor.opacity(0.3), lineWidth: 1)
                                            )
                                            .overlay(
                                                Button(action: {
                                                    withAnimation {
                                                        // Remove images safely
                                                        if index < displayedImages.count && index < selectedPhotos.count {
                                                            displayedImages.remove(at: index)
                                                            selectedPhotos.remove(at: index)
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                                        .padding(8)
                                                }
                                                .buttonStyle(PlainButtonStyle()),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if !displayedImages.isEmpty {
                            PhotosPicker(selection: $selectedPhotos,
                                       maxSelectionCount: 5,
                                       matching: .images) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add More Photos")
                                }
                                .foregroundColor(themeColor)
                                .padding(.vertical, 8)
                            }
                            .disabled(displayedImages.count >= 5)
                            .opacity(displayedImages.count >= 5 ? 0.5 : 1)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Guidelines Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Photo Guidelines")
                            .font(.headline)
                        
                        GuidelineRow(icon: "checkmark.circle.fill", text: "Clear, well-lit photos", isPositive: true)
                        GuidelineRow(icon: "checkmark.circle.fill", text: "Store front or interior", isPositive: true)
                        GuidelineRow(icon: "checkmark.circle.fill", text: "No people in photos", isPositive: true)
                        GuidelineRow(icon: "xmark.circle.fill", text: "No blurry or dark images", isPositive: false)
                        GuidelineRow(icon: "xmark.circle.fill", text: "No inappropriate content", isPositive: false)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Submit Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitPhotos) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(themeColor)
                        } else {
                            Text("Submit")
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(displayedImages.isEmpty || isSubmitting)
                    .foregroundColor(displayedImages.isEmpty || isSubmitting ? themeColor.opacity(0.5) : themeColor)
                }
            }
            .onChange(of: selectedPhotos) { _ in
                Task {
                    await loadImages()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    // If all images were duplicates, dismiss the view
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
                // Only add the image if it's not already in displayedImages
                if !displayedImages.contains(where: { $0.pngData() == image.pngData() }) {
                    newImages.append(image)
                }
            }
        }
        
        // Update displayedImages on the main thread
        await MainActor.run {
            displayedImages.append(contentsOf: newImages)
            // Ensure we don't exceed 5 images
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
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isPositive ? themeColor : .red)
            Text(text)
                .font(.subheadline)
        }
    }
} 
