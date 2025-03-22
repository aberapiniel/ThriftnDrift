import SwiftUI

struct AddFindView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var findsService = FindsService.shared
    
    @State private var description = ""
    @State private var priceText = ""
    @State private var selectedCategory = "Clothing"
    @State private var selectedStore: Store?
    @State private var showingStoreSelector = false
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let categories = ["Clothing", "Furniture", "Electronics", "Books", "Accessories", "Home Goods", "Other"]
    
    private var priceValue: Double {
        return Double(priceText) ?? 0
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && priceValue > 0 && selectedStore != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Store").foregroundColor(ThemeManager.textColor)) {
                    Button(action: { showingStoreSelector = true }) {
                        HStack {
                            if let store = selectedStore {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .foregroundColor(ThemeManager.textColor)
                                    Text(store.address)
                                        .font(.caption)
                                        .foregroundColor(ThemeManager.textColor.opacity(0.7))
                                }
                            } else {
                                Text("Select Store")
                                    .foregroundColor(ThemeManager.brandPurple)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(ThemeManager.textColor.opacity(0.7))
                        }
                    }
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                
                Section(header: Text("Item Details").foregroundColor(ThemeManager.textColor)) {
                    TextField("Description", text: $description)
                        .foregroundColor(ThemeManager.textColor)
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(ThemeManager.textColor)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                                .foregroundColor(ThemeManager.textColor)
                                .tag(category)
                        }
                    }
                    .tint(ThemeManager.brandPurple)
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
                
                Section(header: Text("Photos").foregroundColor(ThemeManager.textColor)) {
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(ThemeManager.brandPurple)
                            Text("Add Photos")
                                .foregroundColor(ThemeManager.brandPurple)
                        }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            Button(action: { selectedImages.remove(at: index) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listRowBackground(ThemeManager.warmOverlay.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(ThemeManager.backgroundStyle)
            .navigationTitle("New Find")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.brandPurple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        submitFind()
                    }
                    .foregroundColor(isFormValid ? ThemeManager.brandPurple : ThemeManager.textColor.opacity(0.3))
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingStoreSelector) {
                StoreSelectionView(selectedStore: $selectedStore)
            }
            .sheet(isPresented: $showingImagePicker) {
                // TODO: Implement ImagePicker
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func submitFind() {
        guard let store = selectedStore else { return }
        
        do {
            try findsService.addFind(
                description: description,
                price: priceValue,
                category: selectedCategory,
                store: store,
                images: selectedImages
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
} 