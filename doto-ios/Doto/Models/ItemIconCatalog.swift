import SwiftUI
import UIKit

/// Granular per-list-type icon pool for shopping items. Icons are auto-detected
/// from the item name and can be overridden from the type's pool in the picker.
/// Reuses `TaskIcon`/`TaskIconCategory` (symbol, label, runtime fallback).
enum ItemIconCatalog {

    /// Picker sections for a list type — the pool is filtered to that type.
    static func sections(for type: ShoppingListType) -> [TaskIconCategory] {
        switch type {
        case .groceries:  return grocerySections
        case .birthday:   return birthdaySections
        case .holiday:    return holidaySections
        case .movies:     return moviesSections
        case .household:  return householdSections
        case .school:     return schoolSections
        case .pharmacy:   return pharmacySections
        case .pet:        return petSections
        case .travel:     return travelSections
        case .hardware:   return hardwareSections
        case .clothing:   return clothingSections
        case .other:      return generalSections
        }
    }

    /// Auto-detect an icon for an item name within a list type's pool.
    /// Rules are checked most-specific first; unmatched names get the
    /// list type's own icon as the default.
    static func detect(from name: String, for type: ShoppingListType) -> String {
        let n = name.lowercased()

        // Shared granular rules — checked for every list type.
        let rules: [(String, [String])] = [
            // food & drink
            ("oval.portrait.fill", ["egg"]),
            ("waterbottle.fill",   ["milk", "water", "juice", "soda", "gatorade"]),
            ("triangle.fill",      ["cheese"]),
            ("birthday.cake.fill", ["bread", "bagel", "cake", "cupcake", "muffin", "tortilla", "donut", "croissant"]),
            ("carrot.fill",        ["apple", "banana", "fruit", "vegetable", "carrot", "lettuce", "potato", "onion", "tomato", "broccoli", "salad"]),
            ("fish.fill",          ["chicken", "beef", "fish", "salmon", "shrimp", "meat", "steak", "pork", "turkey", "bacon", "sausage"]),
            ("snowflake",          ["frozen", "ice cream", "popsicle"]),
            ("archivebox.fill",    ["pasta", "rice", "cereal", "flour", "sugar", "canned", "beans", "soup", "oatmeal"]),
            ("popcorn.fill",       ["chips", "crackers", "popcorn", "cookies", "candy", "pretzel", "granola", "snack"]),
            ("cup.and.saucer.fill",["coffee", "tea", "drink"]),
            ("wineglass",          ["wine", "beer"]),
            ("drop.fill",          ["ketchup", "mustard", "mayo", "sauce", "oil", "vinegar", "honey", "syrup", "dressing", "salt", "pepper", "spice"]),
            ("sparkles",           ["detergent", "dish soap", "cleaner", "bleach", "sponge", "windex", "lysol", "clorox", "wipes"]),
            ("scroll.fill",        ["paper towel", "toilet paper", "tissue", "napkin"]),
            ("heart.fill",         ["shampoo", "conditioner", "toothpaste", "toothbrush", "deodorant", "lotion", "soap", "sunscreen", "razor", "floss"]),
            ("teddybear.fill",     ["diaper", "baby", "formula", "pacifier"]),
            // tech
            ("iphone",             ["iphone", "phone"]),
            ("ipad",               ["ipad", "tablet"]),
            ("laptopcomputer",     ["laptop", "macbook", "chromebook", "notebook computer"]),
            ("desktopcomputer",    ["computer", "monitor", "imac"]),
            ("tv.fill",            ["tv", "television"]),
            ("headphones",         ["headphone", "earbud", "airpod", "speaker"]),
            ("camera.fill",        ["camera", "gopro"]),
            ("applewatch",         ["watch"]),
            ("printer.fill",       ["printer", "ink", "toner"]),
            ("powerplug.fill",     ["charger", "cable", "usb", "adapter", "battery", "cord", "electronic"]),
            ("gamecontroller.fill",["game", "xbox", "playstation", "nintendo", "controller"]),
            ("keyboard",           ["keyboard", "mouse"]),
            // celebration & gifts
            ("gift.fill",          ["gift", "present", "wrapping", "ribbon", "gift card", "card"]),
            ("balloon.fill",       ["balloon", "banner", "streamer", "decor", "confetti", "party"]),
            ("crown.fill",         ["tiara", "crown", "costume"]),
            ("puzzlepiece.fill",   ["lego", "puzzle", "toy", "doll", "figurine"]),
            ("envelope.fill",      ["envelope", "stamp", "invitation"]),
            // household & hardware
            ("hammer.fill",        ["hammer", "nail", "screw"]),
            ("wrench.and.screwdriver.fill", ["wrench", "screwdriver", "drill", "tool", "saw"]),
            ("paintbrush.fill",    ["paint", "brush", "roller", "primer"]),
            ("lightbulb.fill",     ["bulb", "light", "lamp", "batteries"]),
            ("key.fill",           ["key", "lock"]),
            ("basket.fill",        ["basket", "hamper", "bin"]),
            ("washer.fill",        ["laundry", "fabric softener", "dryer sheet"]),
            ("trash.fill",         ["trash bag", "garbage"]),
            // school
            ("pencil",             ["pencil", "pen", "marker", "crayon", "eraser"]),
            ("scissors",           ["scissor", "glue", "tape"]),
            ("ruler.fill",         ["ruler", "protractor"]),
            ("book.fill",          ["book", "textbook", "novel"]),
            ("folder.fill",        ["folder", "binder", "notebook", "paper"]),
            ("backpack.fill",      ["backpack", "lunchbox"]),
            ("paintpalette.fill",  ["paint set", "craft", "glitter"]),
            // pharmacy
            ("pills.fill",         ["medicine", "pill", "tylenol", "ibuprofen", "advil", "vitamin", "supplement", "melatonin", "prescription"]),
            ("bandaid.fill",       ["bandaid", "bandage", "gauze", "first aid", "ointment"]),
            ("cross.case.fill",    ["thermometer", "antiseptic", "mask", "medicine kit"]),
            // pets
            ("pawprint.fill",      ["pet", "dog food", "cat food", "kibble", "leash", "collar", "litter"]),
            ("cat.fill",           ["cat"]),
            ("dog.fill",           ["dog", "puppy"]),
            ("hare.fill",          ["rabbit", "hamster", "bunny"]),
            // travel
            ("suitcase.fill",      ["suitcase", "luggage", "packing"]),
            ("airplane",           ["flight", "plane", "airline"]),
            ("map.fill",           ["map", "passport", "visa", "document", "ticket"]),
            ("umbrella.fill",      ["umbrella", "raincoat"]),
            ("creditcard.fill",    ["credit card", "wallet", "cash"]),
            // clothing
            ("tshirt.fill",        ["shirt", "tshirt", "top", "sweater", "hoodie", "jacket", "dress", "pants", "jeans", "shorts", "skirt", "sock", "underwear", "pajama", "uniform"]),
            ("shoe.fill",          ["shoe", "sneaker", "boot", "sandal", "cleat"]),
            ("eyeglasses",         ["glasses", "sunglasses"]),
            ("bag.fill",           ["bag", "purse", "backpack"]),
            // movies
            ("film.fill",          ["movie", "film", "dvd", "bluray", "show"]),
            ("ticket.fill",        ["ticket"]),
            // flowers & plants
            ("camera.macro",       ["flower", "bouquet", "rose", "tulip", "plant"]),
            ("leaf.fill",          ["plant", "succulent", "soil", "seed", "fertilizer"]),
        ]

        for (symbol, keywords) in rules where keywords.contains(where: { n.contains($0) }) {
            return symbol
        }
        return type.resolvedIcon
    }

    /// Runtime-safe symbol — falls back when the name isn't a real symbol here.
    static func resolve(_ symbol: String) -> String {
        if UIImage(systemName: symbol) != nil { return symbol }
        if let icon = allIcons.first(where: { $0.symbol == symbol }),
           let fallback = icon.fallback {
            return fallback
        }
        return "bag.fill"
    }

    private static let allIcons: [TaskIcon] = {
        ShoppingListType.allCases.flatMap { sections(for: $0).flatMap(\.icons) }
    }()

    // MARK: - Icon pools per list type

    private static let grocerySections = [
        TaskIconCategory(name: "Produce", color: .memberGreen, icons: [
            TaskIcon("carrot.fill", "Fruits & veggies"),
            TaskIcon("leaf.fill", "Greens"),
            TaskIcon("camera.macro", "Herbs & flowers", fallback: "leaf.fill"),
        ]),
        TaskIconCategory(name: "Dairy & Bakery", color: .memberAmber, icons: [
            TaskIcon("oval.portrait.fill", "Eggs", fallback: "oval.fill"),
            TaskIcon("waterbottle.fill", "Milk", fallback: "mug.fill"),
            TaskIcon("triangle.fill", "Cheese"),
            TaskIcon("birthday.cake.fill", "Bread & bakery"),
            TaskIcon("cup.and.saucer.fill", "Butter & spreads"),
        ]),
        TaskIconCategory(name: "Meat & Frozen", color: .memberRed, icons: [
            TaskIcon("fish.fill", "Meat & fish"),
            TaskIcon("fork.knife", "Deli"),
            TaskIcon("snowflake", "Frozen"),
            TaskIcon("refrigerator.fill", "Fridge staples", fallback: "snowflake"),
        ]),
        TaskIconCategory(name: "Pantry & Snacks", color: .memberPurple, icons: [
            TaskIcon("archivebox.fill", "Pantry & dry goods"),
            TaskIcon("popcorn.fill", "Snacks", fallback: "fork.knife"),
            TaskIcon("drop.fill", "Condiments & sauces"),
            TaskIcon("wineglass", "Wine & beer"),
            TaskIcon("takeoutbag.and.cup.and.straw.fill", "Takeout", fallback: "bag.fill"),
        ]),
        TaskIconCategory(name: "Household & Care", color: .memberBlue, icons: [
            TaskIcon("sparkles", "Cleaning"),
            TaskIcon("scroll.fill", "Paper goods", fallback: "doc.fill"),
            TaskIcon("heart.fill", "Personal care"),
            TaskIcon("teddybear.fill", "Baby", fallback: "face.smiling"),
            TaskIcon("basket.fill", "Storage"),
        ]),
        TaskIconCategory(name: "General", color: .textMuted, icons: [
            TaskIcon("cart.fill", "Groceries"),
            TaskIcon("bag.fill", "Bag"),
            TaskIcon("ellipsis.circle.fill", "Other"),
        ]),
    ]

    private static let birthdaySections = [
        TaskIconCategory(name: "Party", color: .memberRed, icons: [
            TaskIcon("gift.fill", "Gift"),
            TaskIcon("balloon.fill", "Balloons", fallback: "gift.fill"),
            TaskIcon("party.popper.fill", "Party", fallback: "gift.fill"),
            TaskIcon("birthday.cake.fill", "Cake"),
            TaskIcon("crown.fill", "Costume"),
            TaskIcon("envelope.fill", "Cards & invites"),
            TaskIcon("music.note", "Music"),
            TaskIcon("star.fill", "Decorations"),
        ]),
        TaskIconCategory(name: "Food & Activities", color: .memberAmber, icons: [
            TaskIcon("popcorn.fill", "Snacks", fallback: "fork.knife"),
            TaskIcon("cup.and.saucer.fill", "Drinks"),
            TaskIcon("pizza.fill", "Pizza", fallback: "fork.knife"),
            TaskIcon("puzzlepiece.fill", "Games & toys"),
            TaskIcon("pin.fill", "Piñata", fallback: "star.fill"),
            TaskIcon("paintpalette.fill", "Crafts"),
        ]),
    ]

    private static let holidaySections = [
        TaskIconCategory(name: "Holiday", color: .memberGreen, icons: [
            TaskIcon("gift.fill", "Gifts"),
            TaskIcon("tree.fill", "Tree & decor", fallback: "leaf.fill"),
            TaskIcon("snowflake", "Winter"),
            TaskIcon("star.fill", "Ornaments"),
            TaskIcon("lightbulb.fill", "Lights"),
            TaskIcon("balloon.fill", "Celebration", fallback: "gift.fill"),
            TaskIcon("flame.fill", "Candles & fireplace"),
            TaskIcon("bell.fill", "Festive"),
        ]),
        TaskIconCategory(name: "Food & More", color: .memberRed, icons: [
            TaskIcon("fork.knife", "Holiday meal"),
            TaskIcon("birthday.cake.fill", "Baking & treats"),
            TaskIcon("wineglass", "Drinks"),
            TaskIcon("tshirt.fill", "Outfits"),
        ]),
    ]

    private static let moviesSections = [
        TaskIconCategory(name: "Movies", color: .memberPurple, icons: [
            TaskIcon("film.fill", "Movie"),
            TaskIcon("ticket.fill", "Tickets", fallback: "film.fill"),
            TaskIcon("tv.fill", "TV show"),
            TaskIcon("popcorn.fill", "Popcorn", fallback: "fork.knife"),
            TaskIcon("play.rectangle.fill", "Streaming"),
            TaskIcon("gamecontroller.fill", "Game night"),
            TaskIcon("hifispeaker.fill", "Sound", fallback: "speaker.wave.2.fill"),
            TaskIcon("cup.and.saucer.fill", "Drinks"),
        ]),
    ]

    private static let householdSections = [
        TaskIconCategory(name: "Cleaning & Supplies", color: .memberBlue, icons: [
            TaskIcon("sparkles", "Cleaning"),
            TaskIcon("bubbles.and.sparkles", "Soap & detergent", fallback: "sparkles"),
            TaskIcon("scroll.fill", "Paper goods", fallback: "doc.fill"),
            TaskIcon("trash.fill", "Trash bags"),
            TaskIcon("washer.fill", "Laundry", fallback: "tshirt.fill"),
            TaskIcon("dishwasher.fill", "Dish soap", fallback: "drop.fill"),
            TaskIcon("basket.fill", "Storage & bins"),
            TaskIcon("wind", "Air fresheners"),
        ]),
        TaskIconCategory(name: "Home", color: .memberAmber, icons: [
            TaskIcon("lightbulb.fill", "Bulbs & batteries"),
            TaskIcon("key.fill", "Keys & locks"),
            TaskIcon("hammer.fill", "Fixes"),
            TaskIcon("powerplug.fill", "Cords & chargers", fallback: "bolt.fill"),
        ]),
    ]

    private static let schoolSections = [
        TaskIconCategory(name: "School Supplies", color: .memberBlue, icons: [
            TaskIcon("pencil", "Pencils & pens"),
            TaskIcon("scissors", "Scissors & glue"),
            TaskIcon("ruler.fill", "Rulers"),
            TaskIcon("book.fill", "Books"),
            TaskIcon("folder.fill", "Folders & notebooks"),
            TaskIcon("backpack.fill", "Backpack"),
            TaskIcon("paintpalette.fill", "Art supplies"),
            TaskIcon("takeoutbag.and.cup.and.straw.fill", "Lunch gear", fallback: "bag.fill"),
        ]),
        TaskIconCategory(name: "Tech & Other", color: .memberPurple, icons: [
            TaskIcon("laptopcomputer", "Laptop"),
            TaskIcon("ipad", "Tablet", fallback: "iphone"),
            TaskIcon("headphones", "Headphones"),
            TaskIcon("tshirt.fill", "Uniforms"),
        ]),
    ]

    private static let pharmacySections = [
        TaskIconCategory(name: "Pharmacy & Health", color: .memberGreen, icons: [
            TaskIcon("pills.fill", "Medicine", fallback: "cross.case.fill"),
            TaskIcon("bandaid.fill", "First aid", fallback: "cross.case.fill"),
            TaskIcon("cross.case.fill", "Health kit"),
            TaskIcon("thermometer.medium", "Thermometer", fallback: "cross.case.fill"),
            TaskIcon("heart.fill", "Wellness"),
            TaskIcon("drop.fill", "Syrups & drops"),
            TaskIcon("sun.max.fill", "Sunscreen"),
            TaskIcon("heart.text.square.fill", "Personal care", fallback: "heart.fill"),
        ]),
    ]

    private static let petSections = [
        TaskIconCategory(name: "Pet Supplies", color: .memberRed, icons: [
            TaskIcon("pawprint.fill", "Pet"),
            TaskIcon("dog.fill", "Dog", fallback: "pawprint.fill"),
            TaskIcon("cat.fill", "Cat", fallback: "pawprint.fill"),
            TaskIcon("fish.fill", "Fish", fallback: "pawprint.fill"),
            TaskIcon("hare.fill", "Small pets", fallback: "pawprint.fill"),
            TaskIcon("bird.fill", "Bird", fallback: "pawprint.fill"),
            TaskIcon("tennisball.fill", "Toys", fallback: "pawprint.fill"),
            TaskIcon("fork.knife", "Pet food"),
            TaskIcon("heart.fill", "Pet health"),
        ]),
    ]

    private static let travelSections = [
        TaskIconCategory(name: "Travel", color: .memberBlue, icons: [
            TaskIcon("suitcase.fill", "Luggage"),
            TaskIcon("airplane", "Flights"),
            TaskIcon("map.fill", "Documents & maps"),
            TaskIcon("camera.fill", "Camera"),
            TaskIcon("sun.max.fill", "Beach & sun"),
            TaskIcon("umbrella.fill", "Rain gear"),
            TaskIcon("creditcard.fill", "Money & cards"),
            TaskIcon("powerplug.fill", "Chargers", fallback: "bolt.fill"),
            TaskIcon("tshirt.fill", "Clothes"),
            TaskIcon("heart.fill", "Toiletries"),
            TaskIcon("backpack.fill", "Daypack"),
            TaskIcon("figure.walk", "Activities"),
        ]),
    ]

    private static let hardwareSections = [
        TaskIconCategory(name: "Hardware & DIY", color: .memberAmber, icons: [
            TaskIcon("hammer.fill", "Tools"),
            TaskIcon("wrench.and.screwdriver.fill", "Wrenches & drivers", fallback: "hammer.fill"),
            TaskIcon("paintbrush.fill", "Paint & brushes"),
            TaskIcon("ruler.fill", "Measuring"),
            TaskIcon("lightbulb.fill", "Electrical"),
            TaskIcon("drop.fill", "Plumbing"),
            TaskIcon("powerplug.fill", "Cords & power", fallback: "bolt.fill"),
            TaskIcon("key.fill", "Locks & keys"),
            TaskIcon("shippingbox.fill", "Materials"),
            TaskIcon("screwdriver.fill", "Screwdriver", fallback: "hammer.fill"),
        ]),
    ]

    private static let clothingSections = [
        TaskIconCategory(name: "Clothing", color: .memberPurple, icons: [
            TaskIcon("tshirt.fill", "Tops"),
            TaskIcon("shoe.fill", "Shoes", fallback: "tshirt.fill"),
            TaskIcon("eyeglasses", "Glasses"),
            TaskIcon("bag.fill", "Bags"),
            TaskIcon("umbrella.fill", "Outerwear"),
            TaskIcon("applewatch", "Accessories", fallback: "clock.fill"),
            TaskIcon("scissors", "Alterations"),
            TaskIcon("washer.fill", "Laundry", fallback: "tshirt.fill"),
        ]),
    ]

    private static let generalSections = [
        TaskIconCategory(name: "General", color: .textMuted, icons: [
            TaskIcon("bag.fill", "Item"),
            TaskIcon("cart.fill", "Shopping"),
            TaskIcon("gift.fill", "Gift"),
            TaskIcon("star.fill", "Important"),
            TaskIcon("tag.fill", "Deal"),
            TaskIcon("bookmark.fill", "Saved"),
            TaskIcon("checkmark.circle.fill", "Done"),
            TaskIcon("ellipsis.circle.fill", "Other"),
        ]),
    ]
}
