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
            .frame(height: 52)

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    let char = code.count > i
                        ? String(code[code.index(code.startIndex, offsetBy: i)])
                        : ""
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isFocused && code.count == i
                                ? Color.memberBlue : Color(hex: "#D1D5DB"),
                            lineWidth: 1.5
                        )
                        .frame(width: 44, height: 52)
                        .overlay(
                            Text(char)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.textPrimary)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
    }
}
