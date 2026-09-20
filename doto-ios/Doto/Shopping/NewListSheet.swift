import SwiftUI

/// New shopping list sheet — name plus a type picker that drives the list icon
/// and, for Groceries, aisle-style subcategory grouping.
struct NewListSheet: View {
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var listType: ShoppingListType = .other
    @State private var isSubmitting = false
    @FocusState private var focusName: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("List name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusName)

                    Text("LIST TYPE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textMuted)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(ShoppingListType.allCases, id: \.self) { type in
                            Button {
                                listType = type
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: type.resolvedIcon)
                                        .font(.system(size: 16))
                                    Text(type.label)
                                        .font(.system(size: 9, weight: .medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundColor(listType == type ? .white : type.color)
                                .background(listType == type ? type.color : type.color.opacity(0.12))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if listType == .groceries {
                        Text("Grocery items get grouped by store section automatically.")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }
                .padding()
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Creating…" : "Create") {
                        Task { await create() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
        .onAppear { focusName = true }
    }

    private func create() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await vm.createList(
            name: name.trimmingCharacters(in: .whitespaces),
            listType: listType.rawValue
        )
        if vm.errorMessage == nil { dismiss() }
    }
}
