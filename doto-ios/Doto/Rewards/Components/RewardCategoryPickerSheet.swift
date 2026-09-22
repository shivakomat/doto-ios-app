import SwiftUI

/// 4-column grid picker for a reward catalog category. Tapping a category
/// applies it and dismisses immediately — a category pick is single-shot,
/// so no separate Done step (unlike `TaskIconPickerView`).
struct RewardCategoryPickerSheet: View {
    @Binding var selected: RewardCategory
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(RewardCategory.allCases, id: \.rawValue) { category in
                        categoryCell(category)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose a Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func categoryCell(_ category: RewardCategory) -> some View {
        let isSelected = selected == category
        return Button {
            selected = category
            dismiss()
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: category.resolvedIcon)
                        .font(.system(size: 20))
                        .foregroundColor(category.color)
                        .frame(width: 52, height: 52)
                        .background(category.color.opacity(0.12))
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
                Text(category.label)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.label)
    }
}
