# Budget App

Personal budget tracker built with Flutter, Provider, and Drift.

## Session Summary (Commit Resume)

This session delivered a full stabilization and feature pass across app architecture, UI flows, data integrity, web support, and tests.

### What Was Implemented

- Stabilized app compile/runtime behavior (including web) and fixed key dialog/runtime/layout regressions.
- Moved to a single shared, app-scoped database instance consumed via providers.
- Implemented and refined Categories flow:
	- category listing
	- add category dialog (name/color/icon)
	- guarded delete behavior
	- protected fallback category for uncategorized expenses
- Enforced one-to-many category-expense relationship using `categoryId` foreign key.
- Added monthly joined expense queries and category-grouped totals.
- Added visual dashboard improvements:
	- category wheel chart
	- category total chips
	- enriched expense rows with category icon/color
- Added expense dialogs:
	- tap expense row for details dialog
	- tap expenses plus button for add-expense dialog
- Extracted reusable widgets (drawer/dialog/body components) for cleaner screens.
- Added demo seeding/reset flow controlled by compile-time flags.
- Centralized UI text catalog and app-wide text provider/context usage.
- Added keyboard/input restrictions and sanitization by field context.
- Expanded DB and widget tests to cover new behaviors.

## Current Architecture

This project follows a **Feature-First Layered Architecture** using **Provider** for state management.

Each feature maps to a screen/domain slice and is organized as:

- `feature/<feature_name>/`
	- `presentation/` (screens + widgets + UI state)
	- `provider/` (state orchestration and view-model-like logic)
	- optional `data/` and `domain/` layers as the feature grows

Shared, cross-cutting code lives in `core/` and is consumed by all features.

In practice, this is commonly referred to as:

- **Feature-first modular structure**
- **Layered architecture (Presentation -> Provider/Application -> Data)**
- **MVVM-like Flutter architecture with Provider** (Provider acting as ViewModel/state holder)

## Architecture Type and Source

- Primary type used here: **Feature-First Layered Architecture with Provider (MVVM-like)**.
- Official Flutter architectural guidance source:
	- https://docs.flutter.dev/app-architecture
- Flutter state management guidance source:
	- https://docs.flutter.dev/data-and-backend/state-mgmt/simple
- Provider package source/reference:
	- https://pub.dev/packages/provider

## High-Level Structure

- `lib/main.dart`
	- App bootstrap, optional demo seed/reset trigger.
- `lib/app.dart`
	- App-level providers (shared DB + text provider), theme, root route.
- `lib/core/`
	- `database/`: Drift schema, migrations, queries, platform connection wiring.
	- `text/`: centralized app text and provider/context extension.
	- `constants/`: protected category defaults and related constants.
	- `dev/`: demo seeding utilities and environment-flag behavior.
	- `utils/`: shared helpers such as input sanitization.
- `lib/feature/home/`
	- Home provider + dashboard UI + expense dialogs/widgets.
- `lib/feature/categories/`
	- Categories provider + page + add category dialog/body widgets.

## Data Layer

- Database engine: Drift
- Core tables:
	- `categories`: `id`, `name`, `color`, `icon`
	- `expenses`: `id`, optional `name`, `amount`, `date`, `categoryId` (FK)
- Key behaviors:
	- joined monthly expense retrieval with category data
	- grouped monthly totals by category
	- protected uncategorized category creation/reuse
	- delete-category reassignment of existing expenses to uncategorized

## State Management

- Provider + ChangeNotifier
- App-scoped dependencies provided once at root (`AppDatabase`, text provider)
- Feature providers consume shared DB and expose UI-ready state

## UI/Presentation

- Home screen:
	- current month + totals
	- wheel chart and category chips
	- expense list and expense details dialog
	- add-expense flow from expenses plus button
- Categories screen:
	- category list
	- add-category flow via FAB dialog
	- guarded category deletion rules

## Web Support

- Drift web storage path uses sqlite3 WASM + worker setup.
- Platform-specific DB connection is selected through conditional connection files.

## Input Rules and Sanitization

- Category name fields:
	- keyboard tuned for text/name entry
	- formatter restricts to letters/spaces
	- sanitizer trims/collapses whitespace and strips unsupported characters
- Expense name fields:
	- formatter restricts to alphanumeric/spaces
	- sanitizer normalizes before persistence
- Amount fields:
	- keyboard restricted to decimal numeric entry
	- formatter restricts to valid numeric pattern with max two decimals
	- sanitizer/parser validates positive amount and normalizes precision

## Testing

## Current Coverage

- Widget tests:
	- app/home smoke validation
	- add-expense dialog open/close flow from home
	- add-category dialog open/close flow from categories page
- Database/unit tests:
	- category insertion and model field validation
	- provider-level category add behavior
	- monthly joined/grouped expense query correctness
	- delete-category reassignment behavior
	- uncategorized-category protection/idempotency behavior
	- expense sanitization/rounding persistence path

## Test Commands

Run app in dev mode with demo seed data:

```bash
flutter run --dart-define=SEED_DEMO=true
```

Run app in dev mode with demo reset + seed:

```bash
flutter run --dart-define=RESET_DEMO=true --dart-define=SEED_DEMO=true
```

Run full suite:

```bash
flutter test
```

Run analyzer:

```bash
dart analyze
```

Run a focused test file:

```bash
flutter test test/widget_test.dart
```

## Next Recommended Improvements

- Add widget tests for invalid-character typing behavior in dialogs.
- Add integration tests for full create-category -> create-expense -> chart/list update flow.
- Continue cleanup of minor style lints (for example, `use_super_parameters`).

## TODO

- Make the app look pretty.
- Add languages module.
- Add theme module.
- Add monthly reports.
- Add monthly winnings to calculate against expenses.
- Add taxes (feature creep).
