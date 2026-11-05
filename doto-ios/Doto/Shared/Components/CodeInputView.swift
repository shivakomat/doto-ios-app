import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: Binding(
                get: { code },
                set: { code = String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6)) }
            ))
            .keyboardType(.default)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .focused($isFocused)
            .opacity(0.001)
            .frame(height: 56)

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    let char = code.count > i
                        ? String(code[code.index(code.startIndex, offsetBy: i)])
                        : ""
                    let active = isFocused && code.count == i
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(active || !char.isEmpty ? Color.dashBlue : Color.dashCardBorder,
                                        lineWidth: active ? 2 : 1.5)
                        )
                        .frame(maxWidth: 52)
                        .frame(height: 56)
                        .overlay(
                            Text(char)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.dashNavy)
                        )
                        .shadow(color: Color.dashNavy.opacity(0.04), radius: 6, x: 0, y: 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
    }
}
