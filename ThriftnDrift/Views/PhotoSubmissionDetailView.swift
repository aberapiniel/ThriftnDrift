import SwiftUI

struct PhotoSubmissionDetailView: View {
    let submission: PhotoSubmission
    let onApprove: () -> Void
    let onReject: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private let themeColor = Color(red: 0.4, green: 0.5, blue: 0.95)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Store Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(submission.storeName)
                            .font(.title2)
                            .foregroundColor(themeColor)
                        Text("Store ID: \(submission.storeId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Photos Carousel
                    VStack {
                        TabView(selection: $currentPage) {
                            ForEach(submission.imageUrls.indices, id: \.self) { index in
                                AsyncImage(url: URL(string: submission.imageUrls[index])) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    ProgressView()
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 300)
                        
                        // Custom page indicator
                        HStack(spacing: 8) {
                            ForEach(submission.imageUrls.indices, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? themeColor : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut, value: currentPage)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Image counter
                        Text("\(currentPage + 1) of \(submission.imageUrls.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    // Submission Info
                    VStack(alignment: .leading, spacing: 12) {
                        if let submitterName = submission.submitterName {
                            Text("Submitted by: \(submitterName)")
                                .font(.subheadline)
                        }
                        Text("Submitted: \(submission.submittedAt.formatted())")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            onReject()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Reject")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            onApprove()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approve")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Review Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 