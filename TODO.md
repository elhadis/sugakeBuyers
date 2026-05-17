# Notification Payload Navigation Fix TODO

- [x] Update `functions/index.js` payload to include big-picture image + rich item data keys
- [ ] Explicitly extract `thumbnailUrl` in `onMessageOpenedApp` / initial-message handlers in `lib/main.dart`
- [ ] Pass required `imageUrl`, `price`, and `title` into `ItemDetailsScreen` for notification navigation
- [ ] Update `lib/mainScreens/item_details_screen.dart` constructor to require notification `imageUrl`, `price`, `title`
- [x] Keep `Image.network()` with loadingBuilder/errorBuilder
- [ ] Run `flutter analyze lib/main.dart lib/mainScreens/item_details_screen.dart`
