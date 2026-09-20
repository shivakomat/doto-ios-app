import SwiftUI
import UIKit

/// A selectable task icon. `symbol` is the raw SF Symbol name stored on the
/// server; `fallback` is rendered when the symbol doesn't exist on this OS.
struct TaskIcon: Identifiable {
    let symbol: String
    let label: String
    let fallback: String?

    var id: String { symbol }

    var resolvedSymbol: String {
        if UIImage(systemName: symbol) != nil { return symbol }
        return fallback ?? TaskIconCatalog.defaultSymbol
    }

    init(_ symbol: String, _ label: String, fallback: String? = nil) {
        self.symbol = symbol
        self.label = label
        self.fallback = fallback
    }
}

/// A picker section — icons grouped under a section header.
/// Icons within a category share one color.
struct TaskIconCategory: Identifiable {
    let name: String
    let color: Color
    let icons: [TaskIcon]

    var id: String { name }
}

/// Master list of task icons for the picker.
enum TaskIconCatalog {

    static let defaultSymbol = "checkmark.circle.fill"

    static let categories: [TaskIconCategory] = [
        TaskIconCategory(name: "Household", color: .memberAmber, icons: [
            TaskIcon("trash.fill", "Garbage"),
            TaskIcon("arrow.3.trianglepath", "Recycling"),
            TaskIcon("dishwasher.fill", "Dishes", fallback: "drop.fill"),
            TaskIcon("washer.fill", "Laundry", fallback: "tshirt.fill"),
            TaskIcon("tshirt.fill", "Folding clothes"),
            TaskIcon("sparkles", "Cleaning"),
            TaskIcon("wind", "Vacuum"),
            TaskIcon("bed.double.fill", "Make bed"),
        ]),
        TaskIconCategory(name: "School & Learning", color: .memberBlue, icons: [
            TaskIcon("book.fill", "Homework"),
            TaskIcon("books.vertical.fill", "Reading"),
            TaskIcon("backpack.fill", "School"),
            TaskIcon("bus.fill", "Bus"),
            TaskIcon("graduationcap.fill", "Graduation"),
            TaskIcon("car.fill", "Car pickup"),
        ]),
        TaskIconCategory(name: "Kitchen & Errands", color: .memberGreen, icons: [
            TaskIcon("cart.fill", "Groceries"),
            TaskIcon("fork.knife", "Cooking"),
            TaskIcon("drop.fill", "Watering plants"),
            TaskIcon("leaf.fill", "Yard work"),
            TaskIcon("pawprint.fill", "Pet care"),
        ]),
        TaskIconCategory(name: "Health & Other", color: .memberMaroon, icons: [
            TaskIcon("stethoscope", "Doctor"),
            TaskIcon("figure.run", "Sports"),
            TaskIcon("music.note", "Music"),
            TaskIcon("doc.text.fill", "Bills"),
            TaskIcon("iphone", "Screen time"),
            TaskIcon("checkmark.circle.fill", "General"),
        ]),
        TaskIconCategory(name: "Personal Care", color: .memberPurple, icons: [
            TaskIcon("shower.fill", "Shower"),
            TaskIcon("moon.fill", "Bedtime"),
            TaskIcon("book.closed.fill", "Reading before bed"),
            TaskIcon("takeoutbag.and.cup.and.straw.fill", "Pack lunch", fallback: "bag.fill"),
            TaskIcon("battery.100.bolt", "Charge devices"),
        ]),
        TaskIconCategory(name: "Extracurricular", color: .memberRed, icons: [
            TaskIcon("pianokeys", "Piano"),
            TaskIcon("figure.dance", "Dance", fallback: "figure.run"),
            TaskIcon("figure.pool.swim", "Swim", fallback: "drop.fill"),
            TaskIcon("paintpalette.fill", "Art"),
            TaskIcon("building.columns.fill", "Library"),
            TaskIcon("gamecontroller.fill", "Video games"),
            TaskIcon("chevron.left.forwardslash.chevron.right", "Coding"),
        ]),
        TaskIconCategory(name: "Outdoor & Seasonal", color: .memberBlue, icons: [
            TaskIcon("snowflake", "Snow"),
            TaskIcon("figure.walk", "Dog walking"),
        ]),
        TaskIconCategory(name: "Family & Celebrations", color: .memberGreen, icons: [
            TaskIcon("gift.fill", "Birthday"),
            TaskIcon("dollarsign.circle.fill", "Allowance"),
        ]),
    ]

    /// Category color for a stored symbol name; nil when not in the catalog.
    static func color(for symbol: String) -> Color? {
        categories.first { $0.icons.contains { $0.symbol == symbol } }?.color
    }

    /// Resolve a stored symbol to one guaranteed to render on this device.
    static func resolve(_ symbol: String) -> String {
        if UIImage(systemName: symbol) != nil { return symbol }
        if let icon = categories.flatMap(\.icons).first(where: { $0.symbol == symbol }),
           let fallback = icon.fallback {
            return fallback
        }
        return defaultSymbol
    }
}
