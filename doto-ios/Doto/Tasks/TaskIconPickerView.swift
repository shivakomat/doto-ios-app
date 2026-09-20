import SwiftUI

/// Grid picker for a task's SF Symbol icon. Selection is applied immediately
/// via `selected`; "Done" just closes the sheet.
struct TaskIconPickerView: View {
    @Binding var selected: String?
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                    ForEach(TaskIconCatalog.categories) { category in
                        Section(header:
                            Text(category.name.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.systemBackground))
                        ) {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(category.icons) { icon in
                                    iconChip(icon, color: category.color)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func iconChip(_ icon: TaskIcon, color: Color) -> some View {
        let isSelected = selected == icon.symbol
        Button {
            selected = icon.symbol
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: icon.resolvedSymbol)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.memberBlue, lineWidth: isSelected ? 3 : 0)
                    )
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.memberBlue)
                        .background(Circle().fill(Color.white).padding(2))
                        .offset(x: 2, y: 2)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.label)
    }
}
