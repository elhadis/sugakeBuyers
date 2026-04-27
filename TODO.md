# Sugake Professional Modular Restructure TODO

- [ ] Task 1: Main Navigation Wrapper
  - [ ] Create `lib/mainScreens/main_wrapper.dart`
  - [ ] Add `google_nav_bar` bottom navigation with tabs:
    - [ ] Home -> `MyHmoeScreen`
    - [ ] Brands -> all brands grid (database)
    - [ ] Stores -> all sellers list (`users` collection)
    - [ ] Featured -> all items where `isFeatured == true`
  - [ ] Wire entry point (`main.dart` or launch route) to wrapper if needed

- [ ] Task 2: Dynamic Home Screen Logic (`lib/mainScreens/my_hmoe_screen.dart`)
  - [ ] Category default includes `All`
  - [ ] Hide Featured slider when selected category != `All`
  - [ ] Show Featured slider only on first load / `All`
  - [ ] Implement microphone logic via `speech_to_text`
  - [ ] Fill search `TextField` from voice result

- [ ] Task 3: Drill-Down Navigation Flow
  - [ ] Create `lib/mainScreens/store_brands_screen.dart` (brands by `sellerUID`)
  - [ ] Create `lib/mainScreens/brand_items_screen.dart` (items by `brandID`)
  - [ ] Stores tab item tap -> Store brands screen
  - [ ] Brand tap -> Brand items screen

- [ ] Task 4: Responsive & Clean Code
  - [ ] Ensure responsive sizing with `MediaQuery` / `LayoutBuilder` / `Flexible` (no rigid fixed layout assumptions)
  - [ ] Add Hero transitions for image flows
  - [ ] Ensure modular widgets:
    - [ ] `lib/widgets/featured_slider_widget.dart`
    - [ ] `lib/widgets/store_card_widget.dart` (new)
    - [ ] `lib/widgets/brand_card_widget.dart` (new)

- [ ] Task 5: Setup command
  - [ ] Provide terminal command:
    - [ ] `flutter pub add speech_to_text google_nav_bar url_launcher shimmer carousel_slider`

- [ ] Firestore field alignment
  - [ ] Ensure item usage is aligned to:
    - [ ] `itemTitle`
    - [ ] `itemPrice`
    - [ ] `isFeatured`

- [ ] Validation
  - [ ] Run `flutter analyze` on changed files
  - [ ] Share test status and remaining coverage per checklist before final completion
