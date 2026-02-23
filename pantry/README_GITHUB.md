# 🍳 Pantry Management App

A comprehensive iOS and iPadOS app for managing your pantry inventory, recipes, and shopping lists with smart features and family sharing.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![iPadOS](https://img.shields.io/badge/iPadOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green.svg)

## ✨ Features

### 🗄️ Pantry Management
- Track all your food and grocery items
- Add photos to items
- Search and filter by category or location
- Expiration date tracking with alerts
- Low stock indicators
- Quick quantity adjustments
- Default categories and storage locations

### 🍳 Recipe System
- Create and manage recipes with photos
- Ingredients and step-by-step instructions
- **Full-screen cooking mode** with built-in timers
- Recipe scaling (adjust servings, quantities auto-update)
- Smart recipe suggestions based on pantry inventory
- Find recipes using specific ingredients
- Favorite recipes

### 🛒 Shopping List
- Create shopping lists with priorities
- Check off items while shopping
- Category organization
- Price estimation and totals
- Show/hide completed items
- Auto-add items from pantry

### 📊 Insights & Analytics
- Inventory statistics (count, value)
- Alert dashboard (expired, expiring, low stock)
- Category breakdown charts
- Quick actions to key features
- "What Can I Make?" suggestions

### 🔗 Smart Integrations
- Items show which recipes use them
- Recipes show ingredient availability from pantry
- Expiring items suggest recipes to use them
- One-tap add to shopping list
- Fuzzy ingredient matching algorithm

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ / iPadOS 17.0+
- macOS Sonoma or later

### Installation

1. Clone the repository:
```bash
git clone https://github.com/lorenschwartz/pantry.git
cd pantry
```

2. Open the project in Xcode:
```bash
open pantry.xcodeproj
```

3. Build and run (⌘R)

### First Launch

On first launch, the app will:
- Create default categories (Produce, Dairy, Proteins, etc.)
- Create default storage locations (Pantry, Refrigerator, Freezer, etc.)
- Show empty states with helpful guidance

## 📱 Screenshots

*Coming soon!*

## 🏗️ Architecture

### Tech Stack
- **Swift** - 100% Swift codebase
- **SwiftUI** - Modern declarative UI
- **SwiftData** - Local persistence with CloudKit sync ready
- **Swift Charts** - Data visualization
- **PhotosPicker** - Native photo selection
- **VisionKit** - Ready for barcode and receipt scanning

### Project Structure
```
pantry/
├── Models/              # SwiftData models
│   ├── PantryItem.swift
│   ├── Recipe.swift
│   ├── Category.swift
│   ├── StorageLocation.swift
│   └── ...
├── Views/               # SwiftUI views
│   ├── Pantry/
│   ├── Recipes/
│   ├── Shopping/
│   ├── Insights/
│   └── ...
├── Services/            # Business logic
│   └── RecipePantryService.swift
└── Documentation/       # Guides and references
```

### Design Patterns
- MVVM architecture
- Service layer for business logic
- SwiftData for data persistence
- Observable models with @Bindable
- Reactive UI with @Query

## 📖 Documentation

Comprehensive documentation is available:

- **[START_HERE.md](START_HERE.md)** - Quick start guide and first steps
- **[RECIPE_GUIDE.md](RECIPE_GUIDE.md)** - Complete recipe feature guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture details
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - API reference and code examples
- **[TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)** - QA testing guide
- **[PHASE1_STATUS.md](PHASE1_STATUS.md)** - Current development status

## 🛣️ Roadmap

### ✅ Phase 1: Foundation (Current - 95% Complete)
- [x] Core pantry management
- [x] Recipe system with cooking mode
- [x] Shopping list functionality
- [x] Insights dashboard
- [x] Smart integrations

### 🚧 Phase 2: Barcode Scanning (Next)
- [ ] Camera-based barcode scanner
- [ ] Product database integration
- [ ] Barcode learning system
- [ ] Auto-fill item details

### 📋 Phase 3: Receipt Processing
- [ ] Receipt camera capture
- [ ] OCR text extraction
- [ ] Batch item addition
- [ ] Receipt history

### 🔔 Phase 4: Smart Features
- [ ] Push notifications for expirations
- [ ] Auto-generated shopping lists
- [ ] Usage analytics
- [ ] Spending insights

### 👨‍👩‍👧‍👦 Phase 5: Family Sharing
- [ ] CloudKit sync activation
- [ ] Multi-device support
- [ ] Shared pantry
- [ ] User attribution

### 🎨 Phase 6: Polish & Launch
- [ ] Home screen widgets
- [ ] Lock screen widgets
- [ ] Siri shortcuts
- [ ] App Store submission

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

### Reporting Issues
Please open an issue with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Device and iOS version

### Feature Requests
Open an issue with:
- Feature description
- Use case / benefit
- Any relevant mockups or examples

## 📄 License

Copyright © 2026 Loren Schwartz. All rights reserved.

This is a personal project. Please contact for licensing inquiries.

## 🙏 Acknowledgments

Built with:
- Apple's native frameworks (SwiftUI, SwiftData, CloudKit)
- SF Symbols for iconography
- Swift Charts for visualizations
- No third-party dependencies!

## 📞 Contact

**Loren Schwartz**
- GitHub: [@lorenschwartz](https://github.com/lorenschwartz)

## 🎯 Project Stats

- **4,750+ lines** of Swift code
- **13 view components**
- **7 data models** with relationships
- **100+ features** implemented
- **95% Phase 1 complete**
- **0 dependencies** - 100% native Apple frameworks

---

Built with ❤️ and Swift
