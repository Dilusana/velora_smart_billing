# Velora— Self Checkout Kiosk Welcome Screen

A Flutter Material 3 welcome screen for a tablet-based supermarket
self-checkout kiosk, optimized for 10"–12" landscape tablets.

## Project structure

```
lib/
  main.dart                  # App entry point, theme, forces landscape
  welcome_screen.dart        # Main screen: header, welcome text, grid, cart button
  models/
    category.dart            # CategoryItem model + the 6 kiosk categories
  widgets/
    category_card.dart       # Reusable glassmorphism category card
    language_button.dart     # Reusable pill language selector button
    cart_button.dart         # Reusable large "My Cart" CTA button
    kiosk_background.dart    # CustomPainter: abstract pattern + green waves
```

## Run

```
flutter pub get
flutter run
```

## Notes

- Category images use `Image.asset("123")`, `Image.asset("456")`, etc. as
  placeholders per spec. Since these aren't real asset paths, `errorBuilder`
  in `CategoryCard` gracefully falls back to a themed icon so the app still
  runs out of the box. To use real artwork, add files under
  `assets/images/`, update the `imageAsset` paths in `models/category.dart`,
  and uncomment the `assets:` section in `pubspec.yaml`.
- Grid is responsive: 3 columns on widths > 900 (typical landscape tablet),
  2 columns otherwise.
- Hero animations are wired on each category's product image
  (`heroTag` in `CategoryItem`) — pair with a matching `Hero` widget on a
  product-listing destination screen for a smooth shared-element transition.
