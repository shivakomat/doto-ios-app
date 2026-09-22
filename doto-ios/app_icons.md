# Doto — App Icon Reference

All SF Symbols used by Tasks and Shopping Lists. `Fallback` is the symbol rendered when the primary isn't available on the device OS (runtime-checked via `UIImage(systemName:)`).

Source files:
- `Doto/Models/TaskType.swift` — task type icons
- `Doto/Models/TaskIcon.swift` — `TaskIconCatalog` (task icon picker)
- `Doto/Models/ShoppingListType.swift` — list type icons
- `Doto/Models/ItemIconCatalog.swift` — shopping item icon pools (per list type)
- `Doto/Models/GrocerySubcategory.swift` — grocery aisle icons (model-level; group headers render as text)

---

## 1. Task Types (4)

Fixed type badge icons — shown on task filter chips and type pickers.

| Type | Symbol | Color |
|---|---|---|
| Chore | `house.fill` | `#F59E0B` |
| Routine | `arrow.triangle.2.circlepath` | `#1D9E75` |
| Homework | `book.fill` | `#3A7BD5` |
| Errand | `bag.fill` | `#8B5CF6` |

---

## 2. Task Icon Picker — `TaskIconCatalog` (79 icons, 10 categories)

User-selectable icon stored per task. Default symbol: `checkmark.circle.fill`.

### Household — `memberAmber` (11)

| Symbol | Label | Fallback |
|---|---|---|
| `trash.fill` | Garbage | — |
| `arrow.3.trianglepath` | Recycling | — |
| `dishwasher.fill` | Dishes | `drop.fill` |
| `washer.fill` | Laundry | `tshirt.fill` |
| `tshirt.fill` | Folding clothes | — |
| `sparkles` | Cleaning | — |
| `wind` | Vacuum | — |
| `bed.double.fill` | Make bed | — |
| `hammer.fill` | Fix / repairs | — |
| `paintbrush.fill` | Painting | — |
| `key.fill` | Lock up | — |

### Tech & Devices — `memberBlue` (11)

| Symbol | Label | Fallback |
|---|---|---|
| `iphone` | Phone | — |
| `ipad` | iPad / Tablet | `iphone` |
| `laptopcomputer` | Laptop | — |
| `desktopcomputer` | Computer | — |
| `tv.fill` | TV | — |
| `headphones` | Headphones | — |
| `camera.fill` | Camera | — |
| `applewatch` | Watch | `clock.fill` |
| `printer.fill` | Printer | — |
| `hifispeaker.fill` | Speaker | `speaker.wave.2.fill` |
| `powerplug.fill` | Electronics | `bolt.fill` |

### School & Learning — `memberBlue` (8)

| Symbol | Label | Fallback |
|---|---|---|
| `book.fill` | Homework | — |
| `books.vertical.fill` | Reading | — |
| `backpack.fill` | School | — |
| `bus.fill` | Bus | — |
| `graduationcap.fill` | Graduation | — |
| `car.fill` | Car pickup | — |
| `pencil` | Writing | — |
| `scissors` | Arts & crafts | — |

### Kitchen & Errands — `memberGreen` (10)

| Symbol | Label | Fallback |
|---|---|---|
| `cart.fill` | Groceries | — |
| `fork.knife` | Cooking | — |
| `bag.fill` | Shopping | — |
| `fuelpump.fill` | Gas station | — |
| `bicycle` | Bike ride | — |
| `drop.fill` | Watering plants | — |
| `leaf.fill` | Yard work | — |
| `pawprint.fill` | Pet care | — |
| `cat.fill` | Cat | `pawprint.fill` |
| `dog.fill` | Dog | `pawprint.fill` |

### Food & Meals — `memberMaroon` (9)

*Note: SF Symbols lacks literal bread/egg/milk glyphs — closest available symbols used.*

| Symbol | Label | Fallback |
|---|---|---|
| `birthday.cake.fill` | Bread & bakery | — |
| `oval.portrait.fill` | Eggs | `oval.fill` |
| `waterbottle.fill` | Milk | `mug.fill` |
| `triangle.fill` | Cheese | — |
| `carrot.fill` | Fruits & veggies | — |
| `fish.fill` | Meat & fish | — |
| `refrigerator.fill` | Frozen food | `snowflake` |
| `popcorn.fill` | Snacks | `fork.knife` |
| `cup.and.saucer.fill` | Drinks | — |

### Health & Other — `memberMaroon` (5)

| Symbol | Label | Fallback |
|---|---|---|
| `stethoscope` | Doctor | — |
| `figure.run` | Sports | — |
| `music.note` | Music | — |
| `doc.text.fill` | Bills | — |
| `checkmark.circle.fill` | General | — |

### Personal Care — `memberPurple` (5)

| Symbol | Label | Fallback |
|---|---|---|
| `shower.fill` | Shower | — |
| `moon.fill` | Bedtime | — |
| `book.closed.fill` | Reading before bed | — |
| `takeoutbag.and.cup.and.straw.fill` | Pack lunch | `bag.fill` |
| `battery.100.bolt` | Charge devices | — |

### Extracurricular — `memberRed` (11)

| Symbol | Label | Fallback |
|---|---|---|
| `pianokeys` | Piano | — |
| `figure.dance` | Dance | `figure.run` |
| `figure.pool.swim` | Swim | `drop.fill` |
| `soccerball` | Soccer | `figure.run` |
| `basketball.fill` | Basketball | `figure.run` |
| `football.fill` | Football | `figure.run` |
| `baseball.fill` | Baseball | `figure.run` |
| `paintpalette.fill` | Art | — |
| `building.columns.fill` | Library | — |
| `gamecontroller.fill` | Video games | — |
| `chevron.left.forwardslash.chevron.right` | Coding | — |

### Outdoor & Seasonal — `memberBlue` (5)

| Symbol | Label | Fallback |
|---|---|---|
| `sun.max.fill` | Play outside | — |
| `tree.fill` | Park | `leaf.fill` |
| `snowflake` | Snow | — |
| `figure.walk` | Dog walking | — |
| `tent.fill` | Camping | `mountain.2.fill` |

### Family & Celebrations — `memberGreen` (4)

| Symbol | Label | Fallback |
|---|---|---|
| `gift.fill` | Birthday | — |
| `balloon.fill` | Party | `gift.fill` |
| `person.3.fill` | Family time | — |
| `dollarsign.circle.fill` | Allowance | — |

---

## 3. Shopping List Types (12)

List icon shown on the tab strip; also the fallback item icon for that list.

| Type | Symbol | Color | Fallback |
|---|---|---|---|
| Groceries | `cart.fill` | `memberGreen` | — |
| Birthday | `gift.fill` | `memberRed` | — |
| Holiday | `sparkles` | `memberPurple` | — |
| Movies | `popcorn.fill` | `memberAmber` | `film.fill` |
| Household Supplies | `house.fill` | `memberBlue` | — |
| School Supplies | `backpack.fill` | `memberPurple` | `book.fill` |
| Pharmacy / Health | `cross.case.fill` | `memberGreen` | — |
| Pet Supplies | `pawprint.fill` | `memberRed` | `hare.fill` |
| Travel / Packing | `suitcase.fill` | `memberBlue` | — |
| Hardware / DIY | `wrench.and.screwdriver.fill` | `memberAmber` | `hammer.fill` |
| Clothing | `tshirt.fill` | `memberPurple` | — |
| Other | `checklist` | `textMuted` | `list.bullet` |

---

## 4. Shopping Item Icons — `ItemIconCatalog`

Per-list-type picker pools + auto-detection from item names. Unmatched names fall back to the list type's icon.

### Groceries (25)

| Section | Symbols |
|---|---|
| Produce | `carrot.fill`, `leaf.fill`, `camera.macro` |
| Dairy & Bakery | `oval.portrait.fill`, `waterbottle.fill`, `triangle.fill`, `birthday.cake.fill`, `cup.and.saucer.fill` |
| Meat & Frozen | `fish.fill`, `fork.knife`, `snowflake`, `refrigerator.fill` |
| Pantry & Snacks | `archivebox.fill`, `popcorn.fill`, `drop.fill`, `wineglass`, `takeoutbag.and.cup.and.straw.fill` |
| Household & Care | `sparkles`, `scroll.fill`, `heart.fill`, `teddybear.fill`, `basket.fill` |
| General | `cart.fill`, `bag.fill`, `ellipsis.circle.fill` |

### Birthday (14)

| Section | Symbols |
|---|---|
| Party | `gift.fill`, `balloon.fill`, `party.popper.fill`, `birthday.cake.fill`, `crown.fill`, `envelope.fill`, `music.note`, `star.fill` |
| Food & Activities | `popcorn.fill`, `cup.and.saucer.fill`, `pizza.fill`, `puzzlepiece.fill`, `pin.fill`, `paintpalette.fill` |

### Holiday (12)

| Section | Symbols |
|---|---|
| Holiday | `gift.fill`, `tree.fill`, `snowflake`, `star.fill`, `lightbulb.fill`, `balloon.fill`, `flame.fill`, `bell.fill` |
| Food & More | `fork.knife`, `birthday.cake.fill`, `wineglass`, `tshirt.fill` |

### Movies (8)

`film.fill`, `ticket.fill`, `tv.fill`, `popcorn.fill`, `play.rectangle.fill`, `gamecontroller.fill`, `hifispeaker.fill`, `cup.and.saucer.fill`

### Household (12)

| Section | Symbols |
|---|---|
| Cleaning & Supplies | `sparkles`, `bubbles.and.sparkles`, `scroll.fill`, `trash.fill`, `washer.fill`, `dishwasher.fill`, `basket.fill`, `wind` |
| Home | `lightbulb.fill`, `key.fill`, `hammer.fill`, `powerplug.fill` |

### School (12)

| Section | Symbols |
|---|---|
| School Supplies | `pencil`, `scissors`, `ruler.fill`, `book.fill`, `folder.fill`, `backpack.fill`, `paintpalette.fill`, `takeoutbag.and.cup.and.straw.fill` |
| Tech & Other | `laptopcomputer`, `ipad`, `headphones`, `tshirt.fill` |

### Pharmacy (8)

`pills.fill`, `bandaid.fill`, `cross.case.fill`, `thermometer.medium`, `heart.fill`, `drop.fill`, `sun.max.fill`, `heart.text.square.fill`

### Pet (9)

`pawprint.fill`, `dog.fill`, `cat.fill`, `fish.fill`, `hare.fill`, `bird.fill`, `tennisball.fill`, `fork.knife`, `heart.fill`

### Travel (12)

`suitcase.fill`, `airplane`, `map.fill`, `camera.fill`, `sun.max.fill`, `umbrella.fill`, `creditcard.fill`, `powerplug.fill`, `tshirt.fill`, `heart.fill`, `backpack.fill`, `figure.walk`

### Hardware (10)

`hammer.fill`, `wrench.and.screwdriver.fill`, `paintbrush.fill`, `ruler.fill`, `lightbulb.fill`, `drop.fill`, `powerplug.fill`, `key.fill`, `shippingbox.fill`, `screwdriver.fill`

### Clothing (8)

`tshirt.fill`, `shoe.fill`, `eyeglasses`, `bag.fill`, `umbrella.fill`, `applewatch`, `scissors`, `washer.fill`

### Other / General (8)

`bag.fill`, `cart.fill`, `gift.fill`, `star.fill`, `tag.fill`, `bookmark.fill`, `checkmark.circle.fill`, `ellipsis.circle.fill`

---

## 5. Grocery Aisle Icons — `GrocerySubcategory` (13)

Stored on the model; group headers in the list view currently render as text only.

| Category value | Label | Symbol | Fallback |
|---|---|---|---|
| `produce` | Produce | `leaf.fill` | — |
| `dairy_eggs` | Dairy & Eggs | `carton.fill` | `cup.and.saucer.fill` |
| `bakery` | Bakery | `birthday.cake.fill` | `takeoutbag.and.cup.and.straw.fill` |
| `meat_seafood` | Meat & Seafood | `fish.fill` | `fork.knife` |
| `frozen` | Frozen | `snowflake` | — |
| `pantry` | Pantry & Dry Goods | `archivebox.fill` | — |
| `snacks` | Snacks | `popcorn.fill` | `birthday.cake.fill` |
| `beverages` | Beverages | `waterbottle.fill` | `cup.and.saucer.fill` |
| `condiments` | Condiments & Sauces | `drop.fill` | — |
| `household` | Household & Cleaning | `sparkles` | — |
| `personal_care` | Personal Care | `heart.fill` | — |
| `baby` | Baby | `figure.and.child.holdinghands` | `face.smiling` |
| `other` | Other | `ellipsis.circle.fill` | — |

---

## Totals

| Surface | Count |
|---|---|
| Task type icons | 4 |
| Task picker icons | 79 (10 categories) |
| Shopping list type icons | 12 |
| Shopping item picker icons | 146 across 12 list-type pools (with repeats across types) |
| Grocery aisle icons (model) | 13 |
| **Unique symbols** | ~110 |
