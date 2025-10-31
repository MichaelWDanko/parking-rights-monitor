# MVVM Architecture Refactor Plan

## Overview

Move business logic, state management, and validation from views into ViewModels to properly follow MVVM patterns.

## Architecture Decision

- Use the Observation framework’s `@Observable` macro for all new and refactored ViewModels (iOS 17+/Swift 5.9+). This replaces `ObservableObject` + `@Published`.
- In views, hold VMs with `@State var viewModel = ...` (not `@StateObject`). Use `@Bindable` for two-way bindings in subviews.
- Ensure UI-driving mutations occur on the main actor.

## Current Issues Identified

### Critical (Major MVVM Violations)

1. **ParkingRightListView** - Contains state management and API calls

   - `@State` properties: `searchText`, `parkingRights`, `isLoadingRights`, `rightsError`
   - `loadParkingRights()` method performs API calls
   - `filteredRights` computed property for filtering logic

2. **ParkingSessionEventView** - Contains extensive business logic

   - 20+ `@State` properties for form fields
   - `generateRandomVehicle()`, `generateRandomFees()` - utility methods
   - `loadZonesForOperator()` - API call logic
   - `submitStartSession()` - business logic
   - `isStartFormValid` - validation logic
   - `clearStartForm()` - state management

### Minor (Could be improved)

3. **AddOperatorView** / **EditOperatorView** - Validation logic in views
4. **OperatorSelectionView** - Direct SwiftData manipulation (acceptable but could use ViewModel)

## Refactoring Plan

### Phase 1: Create ParkingRightListViewModel

**File:** `ViewModels/ParkingRightListViewModel.swift` (new)

- Move all `@State` properties from `ParkingRightListView`
- Move `loadParkingRights()` method
- Move `filteredRights` computed property
- Use `@Observable` macro (modern Swift, consistent with `OperatorViewModel`)
- Update `ParkingRightListView` to use the ViewModel

### Phase 2: Create ParkingSessionEventFormViewModel

**File:** `ViewModels/ParkingSessionEventFormViewModel.swift` (new)

- Move all form-related `@State` properties from `ParkingSessionEventView`
- Move `generateRandomVehicle()`, `generateRandomFees()` methods
- Move `loadZonesForOperator()` method
- Move `isStartFormValid` computed property
- Move `clearStartForm()` method
- Move `submitStartSession()` orchestration logic (keep API calls in existing `ParkingSessionEventViewModel`)
- Note: Keep `ParkingSessionEventViewModel` for session management, create separate ViewModel for form state

### Phase 3: Create OperatorFormViewModel (Optional Enhancement)

**Files:** `ViewModels/AddOperatorViewModel.swift`, `ViewModels/EditOperatorViewModel.swift` (new)

- Move validation logic from `AddOperatorView` and `EditOperatorView`
- Move save/update logic orchestration
- Keep direct SwiftData operations acceptable if preferred

## Implementation Details

### ParkingRightListViewModel Pattern

- Follow pattern from `OperatorViewModel` (use `@Observable`)
- Store `PassportAPIService` reference
- Handle loading states and errors
- Provide filtered results based on search

### ParkingSessionEventFormViewModel Pattern

- Manage form state (all input fields)
- Handle zone loading when operator changes
- Provide validation state
- Coordinate with existing `ParkingSessionEventViewModel` for API operations

### View Updates

- Views should only bind to ViewModel properties
- Views should only call ViewModel methods
- Remove all business logic from views
- Keep only presentation/UI logic in views

## High-level ViewModel Template (using @Observable)

```swift
import Foundation
import Observation

@Observable
final class ExampleViewModel {
    // Inputs/state
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    // Data
    var items: [Item] = []

    // Dependencies
    private let service: ItemService

    init(service: ItemService) {
        self.service = service
    }

    // Derived state
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // Actions
    func load() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.fetchItems()
                await MainActor.run {
                    self.items = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
```

Usage in a SwiftUI view with bindings:

```swift
import SwiftUI
import Observation

struct ExampleView: View {
    @State private var viewModel = ExampleViewModel(service: .live)

    var body: some View {
        let vm = viewModel // or: @Bindable var vm = viewModel for two-way bindings
        VStack {
            TextField("Search", text: Binding(
                get: { vm.searchText },
                set: { vm.searchText = $0 }
            ))
            if vm.isLoading { ProgressView() }
            List(vm.filteredItems) { item in Text(item.name) }
        }
        .onAppear { vm.load() }
    }
}
```

Notes:

- Prefer `@Bindable var vm = viewModel` inside subviews for concise `$vm.property` bindings.
- Keep long-running/async work off the main thread, but hop to `MainActor.run` to update UI state.

## Files to Modify

### New Files

- `PassportAPIExplorer/ViewModels/ParkingRightListViewModel.swift`
- `PassportAPIExplorer/ViewModels/ParkingSessionEventFormViewModel.swift`
- `PassportAPIExplorer/ViewModels/AddOperatorViewModel.swift` (optional)
- `PassportAPIExplorer/ViewModels/EditOperatorViewModel.swift` (optional)

### Modified Files

- `PassportAPIExplorer/Views/ParkingRightListView.swift`
- `PassportAPIExplorer/Views/ParkingSessionEventView.swift`
- `PassportAPIExplorer/Views/AddOperatorView.swift` (if creating ViewModel)
- `PassportAPIExplorer/Views/EditOperatorView.swift` (if creating ViewModel)

## MVVM Principles Applied

- **Models**: Data structures (already correct)
- **Views**: Only UI/presentation logic (to be fixed)
- **ViewModels**: Business logic, state management, validation (to be created/expanded)