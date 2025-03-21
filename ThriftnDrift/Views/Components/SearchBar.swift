import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                .font(.system(size: 17))
            
            TextField("Search stores...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 17))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.95))
                        .font(.system(size: 17))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.95))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
} 