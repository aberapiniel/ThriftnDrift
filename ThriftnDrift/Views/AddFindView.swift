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
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    private var priceValue: Double {
        return Double(priceText) ?? 0
    }
    
    private var isFormValid: Bool {
        !description.isEmpty && priceValue > 0 && selectedStore != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Store")) {
                    Button(action: { showingStoreSelector = true }) {
                        HStack {
                            if let store = selectedStore {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .foregroundColor(.primary)
                                    Text(store.address)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("Select Store")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Item Details")) {
                    TextField("Description", text: $description)
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Photos")) {
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Add Photos")
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
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            }
            .navigationTitle("New Find")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        submitFind()
                    }
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