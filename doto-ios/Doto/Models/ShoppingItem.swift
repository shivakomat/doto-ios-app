import Foundation

struct ShoppingItem: Codable, Identifiable {
    let id: String
    let listId: String
    let familyId: String
    var name: String
    var quantity: String?
    var category: String
    var isChecked: Bool
    var checkedBy: String?
    var checkedAt: Date?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
}

enum ShoppingCategory: String, CaseIterable {
    case vegetables   = "vegetables"
    case fruits       = "fruits"
    case dairy        = "dairy"
    case meat         = "meat"
    case bakery       = "bakery"
    case desserts     = "desserts"
    case grains       = "grains"
    case condiments   = "condiments"
    case canned       = "canned"
    case beverages    = "beverages"
    case frozen       = "frozen"
    case household    = "household"
    case personalCare = "personal_care"
    case electronics  = "electronics"
    case gifts        = "gifts"
    case flowers      = "flowers"
    case other        = "other"

    var emoji: String {
        switch self {
        case .vegetables:   return "🥬"
        case .fruits:       return "🍎"
        case .dairy:        return "🧀"
        case .meat:         return "🥩"
        case .bakery:       return "🍞"
        case .desserts:     return "🍰"
        case .grains:       return "🌾"
        case .condiments:   return "🧂"
        case .canned:       return "🥫"
        case .beverages:    return "☕"
        case .frozen:       return "❄️"
        case .household:    return "🧹"
        case .personalCare: return "🧴"
        case .electronics:  return "🔌"
        case .gifts:        return "🎁"
        case .flowers:      return "💐"
        case .other:        return "🛒"
        }
    }

    var displayName: String {
        switch self {
        case .vegetables:   return "Vegetables"
        case .fruits:       return "Fruits"
        case .dairy:        return "Dairy & Eggs"
        case .meat:         return "Meat & Seafood"
        case .bakery:       return "Bakery & Bread"
        case .desserts:     return "Desserts"
        case .grains:       return "Grains & Pasta"
        case .condiments:   return "Condiments & Spices"
        case .canned:       return "Canned Goods"
        case .beverages:    return "Beverages"
        case .frozen:       return "Frozen"
        case .household:    return "Cleaning & Household"
        case .personalCare: return "Personal Care"
        case .electronics:  return "Electronics"
        case .gifts:        return "Gifts"
        case .flowers:      return "Flowers & Plants"
        case .other:        return "Other"
        }
    }

    static func detect(from name: String) -> ShoppingCategory {
        let n = name.lowercased()

        let categories: [(ShoppingCategory, [String])] = [
            // Vegetables
            (.vegetables, [
                "vegetable", "spinach", "lettuce", "kale", "cabbage", "arugula",
                "carrot", "potato", "sweet potato", "broccoli", "cauliflower",
                "asparagus", "celery", "cucumber", "zucchini", "squash", "pumpkin",
                "onion", "garlic", "shallot", "leek", "scallion", "green onion",
                "bell pepper", "jalapeno", "pepper", "tomato", "mushroom",
                "corn", "peas", "green bean", "edamame", "bean sprout",
                "beet", "radish", "turnip", "parsnip", "artichoke", "eggplant",
                "okra", "fennel", "brussels sprout", "bok choy",
            ]),
            // Fruits
            (.fruits, [
                "fruit", "apple", "banana", "orange", "lemon", "lime",
                "grape", "blueberry", "strawberry", "raspberry", "blackberry",
                "cherry", "mango", "papaya", "pineapple", "kiwi", "peach",
                "pear", "plum", "apricot", "nectarine", "watermelon",
                "cantaloupe", "honeydew", "coconut", "avocado", "fig",
                "pomegranate", "grapefruit", "tangerine", "clementine",
                "cranberry", "dragon fruit", "passion fruit", "guava", "lychee",
            ]),
            // Dairy & Eggs
            (.dairy, [
                "milk", "cheese", "yogurt", "butter", "cream", "egg",
                "cheddar", "mozzarella", "parmesan", "feta", "brie", "gouda",
                "cream cheese", "cottage cheese", "ricotta", "sour cream",
                "half and half", "whipping cream", "buttermilk", "ghee",
                "kefir", "margarine", "creamer",
            ]),
            // Meat & Seafood
            (.meat, [
                "chicken", "beef", "pork", "turkey", "lamb", "steak",
                "ground beef", "bacon", "ham", "sausage", "hot dog",
                "salmon", "tuna", "shrimp", "crab", "lobster", "fish",
                "tilapia", "cod", "halibut", "scallop", "clam", "mussel",
                "prawn", "pepperoni", "salami", "deli", "veal", "bison",
                "duck", "ribs", "brisket", "meatball", "bratwurst", "chorizo",
            ]),
            // Bakery & Bread
            (.bakery, [
                "bread", "bagel", "croissant", "baguette", "tortilla", "wrap",
                "pita", "naan", "roll", "bun", "english muffin", "sourdough",
                "ciabatta", "focaccia", "flatbread", "brioche",
            ]),
            // Desserts
            (.desserts, [
                "cake", "cookie", "brownie", "pie", "muffin", "donut",
                "cupcake", "pastry", "ice cream", "chocolate", "candy",
                "cheesecake", "tart", "eclair", "macaron", "flan", "pudding",
                "gelato", "sorbet", "waffle", "pancake mix",
            ]),
            // Grains & Pasta
            (.grains, [
                "rice", "pasta", "spaghetti", "penne", "macaroni", "noodle",
                "fettuccine", "linguine", "fusilli", "orzo", "couscous",
                "oatmeal", "cereal", "granola", "flour", "quinoa", "barley",
                "ramen", "udon", "cornmeal", "grits", "polenta",
            ]),
            // Condiments & Spices
            (.condiments, [
                "salt", "pepper", "ketchup", "mustard", "mayo", "mayonnaise",
                "soy sauce", "hot sauce", "vinegar", "olive oil", "cooking oil",
                "honey", "maple syrup", "sugar", "cinnamon", "cumin", "paprika",
                "oregano", "basil", "thyme", "rosemary", "garlic powder",
                "onion powder", "chili powder", "curry", "turmeric", "nutmeg",
                "salsa", "bbq sauce", "ranch", "dressing", "relish",
            ]),
            // Canned Goods
            (.canned, [
                "canned", "soup", "tomato sauce", "tomato paste", "beans",
                "chickpea", "lentil", "tuna can", "broth", "stock",
                "diced tomato", "crushed tomato", "coconut milk",
                "enchilada sauce", "marinara",
            ]),
            // Beverages
            (.beverages, [
                "water", "juice", "coffee", "tea", "soda", "cola",
                "lemonade", "smoothie", "energy drink", "kombucha",
                "sparkling", "wine", "beer", "milk alternative",
                "almond milk", "oat milk", "soy milk",
            ]),
            // Frozen
            (.frozen, [
                "frozen", "frozen pizza", "frozen vegetable", "frozen fruit",
                "frozen dinner", "frozen meal", "tv dinner",
                "fish sticks", "chicken nuggets", "frozen fries",
                "popsicle", "frozen yogurt",
            ]),
            // Cleaning & Household
            (.household, [
                "dish soap", "detergent", "laundry", "bleach", "cleaner",
                "disinfectant", "sponge", "paper towel", "toilet paper",
                "trash bag", "aluminum foil", "plastic wrap", "ziplock",
                "windex", "lysol", "clorox", "mop", "broom", "duster",
                "air freshener", "candle", "light bulb", "battery",
                "tissue", "napkin",
            ]),
            // Personal Care
            (.personalCare, [
                "shampoo", "conditioner", "body wash", "soap", "lotion",
                "deodorant", "toothpaste", "toothbrush", "floss",
                "mouthwash", "razor", "sunscreen", "moisturizer",
                "face wash", "hand sanitizer", "cotton ball", "bandaid",
                "medicine", "vitamin", "ibuprofen", "tylenol",
                "diaper", "baby wipe", "feminine",
            ]),
            // Electronics
            (.electronics, [
                "charger", "cable", "usb", "hdmi", "adapter", "battery",
                "headphone", "earbud", "airpod", "speaker", "bluetooth",
                "phone", "tablet", "laptop", "computer", "mouse", "keyboard",
                "power bank", "extension cord", "surge protector", "sd card",
                "flash drive", "hard drive", "monitor", "webcam", "remote",
            ]),
            // Gifts
            (.gifts, [
                "gift", "present", "card", "greeting card", "birthday card",
                "wrapping paper", "gift bag", "gift wrap", "ribbon", "bow",
                "gift card", "toy", "stuffed animal", "game", "puzzle",
            ]),
            // Flowers & Plants
            (.flowers, [
                "flower", "bouquet", "rose", "tulip", "sunflower", "lily",
                "orchid", "daisy", "carnation", "plant", "succulent",
                "potting soil", "planter", "vase", "seeds", "fertilizer",
            ]),
        ]

        for (category, keywords) in categories {
            if keywords.contains(where: n.contains) {
                return category
            }
        }

        return .other
    }
}
