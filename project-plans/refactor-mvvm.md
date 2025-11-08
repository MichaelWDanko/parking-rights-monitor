# MVVM Architecture Refactor Plan

## Overview

Move business logic, state management, and validation from views into ViewModels to properly follow MVVM patterns.

## Status: ✅ COMPLETED

All critical MVVM violations have been resolved. The codebase now follows MVVM patterns with proper separation of concerns.

## Architecture Decision

- Use the Observation framework’s `@Observable` macro for all new and refactored ViewModels (iOS 17+/Swift 5.9+). This replaces `ObservableObject` + `@Published`.
- In views, hold VMs with `@State var viewModel = ...` (not `@StateObject`). Use `@Bindable` for two-way bindings in subviews.
- Ensure UI-driving mutations occur on the main actor.

## Issues Identified (All Resolved ✅)

### ✅ Critical (Major MVVM Violations) - RESOLVED

1. ✅ **ParkingRightListView** - State management and API calls moved to ViewModel

   - ✅ Moved `@State` properties: `searchText`, `parkingRights`, `isLoadingRights`, `rightsError` → `ParkingRightListViewModel`
   - ✅ Moved `loadParkingRights()` method → `ParkingRightListViewModel`
   - ✅ Moved `filteredRights` computed property → `ParkingRightListViewModel`

2. ✅ **ParkingSessionEventView** - Business logic moved to ViewModels

   - ✅ Moved 20+ `@State` properties for form fields → `ParkingSessionEventFormViewModel`
   - ✅ Moved `generateRandomVehicle()`, `generateRandomFees()` → `ParkingSessionEventFormViewModel`
   - ✅ Moved `loadZonesForOperator()` → `ParkingSessionEventFormViewModel`
   - ✅ Moved `submitStartSession()`, `submitExtendSession()`, `submitStopSession()` → `ParkingSessionEventFormViewModel`
   - ✅ Moved `isStartFormValid` → `ParkingSessionEventFormViewModel`
   - ✅ Moved `clearStartForm()` → `ParkingSessionEventFormViewModel`
   - ✅ Split session management into `ParkingSessionsListViewModel` (CRUD operations)
   - ✅ Split API event publishing into `ParkingSessionEventPublisherViewModel` (API interactions)

### ✅ Minor (Could be improved) - COMPLETED

3. ✅ **AddOperatorView** / **EditOperatorView** - Validation logic moved to ViewModels
4. **OperatorSelectionView** - Direct SwiftData manipulation (acceptable as-is; uses `@Query` which is SwiftUI's recommended pattern for SwiftData)

## Refactoring Plan

### ✅ Phase 1: Create ParkingRightListViewModel - COMPLETED

**File:** `Features/ParkingRights/ViewModels/ParkingRightListViewModel.swift` ✅

- ✅ Moved all `@State` properties from `ParkingRightListView`
- ✅ Moved `loadParkingRights()` method
- ✅ Moved `filteredRights` computed property
- ✅ Used `@Observable` macro (modern Swift, consistent with `OperatorViewModel`)
- ✅ Updated `ParkingRightListView` to use the ViewModel

### ✅ Phase 2: Create ParkingSessionEventFormViewModel - COMPLETED

**File:** `Features/ParkingSessions/ViewModels/ParkingSessionEventFormViewModel.swift` ✅

- ✅ Moved all form-related `@State` properties from `ParkingSessionEventView`
- ✅ Moved `generateRandomVehicle()`, `generateRandomFees()` methods
- ✅ Moved `loadZonesForOperator()` method
- ✅ Moved `isStartFormValid` computed property
- ✅ Moved `clearStartForm()` method
- ✅ Moved `submitStartSession()`, `submitExtendSession()`, `submitStopSession()` orchestration logic

**Additional Work Completed:**

- ✅ Split `ParkingSessionEventViewModel` into three focused ViewModels:
  - `ParkingSessionsListViewModel` - Manages the collection of `ParkingSession` objects (CRUD operations, SwiftData sync)
  - `ParkingSessionEventPublisherViewModel` - Handles publishing events to the Passport API (started, extended, stopped)
  - `ParkingSessionEventFormViewModel` - Manages form state and validation for creating/editing sessions
- ✅ Renamed `ParkingSessionEventListViewModel` → `ParkingSessionsListViewModel` to reflect that it manages sessions (not events)
- ✅ Updated all references across the codebase

### ✅ Phase 3: Create OperatorFormViewModel - COMPLETED

**Files:** 
- `Features/Operators/ViewModels/AddOperatorViewModel.swift` ✅
- `Features/Operators/ViewModels/EditOperatorViewModel.swift` ✅

- ✅ Moved validation logic from `AddOperatorView` and `EditOperatorView`
- ✅ Moved save/update logic orchestration
- ✅ Used `@Observable` macro with `@Bindable` for two-way bindings

### ✅ Additional: Feature-Based Folder Structure - COMPLETED

- ✅ Organized files into feature-based folders:
  - `Features/Operators/` - Operator-related Views and ViewModels
  - `Features/ParkingRights/` - Parking Rights Views and ViewModels
  - `Features/ParkingSessions/` - Parking Sessions Views and ViewModels
  - `Features/Settings/` - Settings Views
  - `Shared/Views/` - Shared Views (ContentView)
- ✅ Updated all file references and verified build succeeds

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

## Files Created/Modified

### ✅ New Files Created

- ✅ `Features/ParkingRights/ViewModels/ParkingRightListViewModel.swift`
- ✅ `Features/ParkingSessions/ViewModels/ParkingSessionEventFormViewModel.swift`
- ✅ `Features/ParkingSessions/ViewModels/ParkingSessionsListViewModel.swift`
- ✅ `Features/ParkingSessions/ViewModels/ParkingSessionEventPublisherViewModel.swift`
- ✅ `Features/Operators/ViewModels/AddOperatorViewModel.swift`
- ✅ `Features/Operators/ViewModels/EditOperatorViewModel.swift`

### ✅ Modified Files

- ✅ `Features/ParkingRights/Views/ParkingRightListView.swift`
- ✅ `Features/ParkingSessions/Views/ParkingSessionEventView.swift`
- ✅ `Features/Operators/Views/AddOperatorView.swift`
- ✅ `Features/Operators/Views/EditOperatorView.swift`
- ✅ `Shared/Views/ContentView.swift` (updated tab label to "Parking Sessions")

### File Organization

- ✅ All files reorganized into feature-based folder structure
- ✅ Old `ViewModels/` and `Views/` directories cleaned up

## MVVM Principles Applied

- ✅ **Models**: Data structures (already correct)
- ✅ **Views**: Only UI/presentation logic (now properly separated)
- ✅ **ViewModels**: Business logic, state management, validation (all created and properly structured)

## Remaining Work

### None - All Critical MVVM Violations Resolved ✅

**Optional Future Enhancements:**

1. **OperatorSelectionView** - Could create a ViewModel if needed, but current implementation using `@Query` is acceptable and follows SwiftUI/SwiftData best practices for simple list views.

2. **Settings Views** - Currently simple views with minimal logic. Could add ViewModels if they grow in complexity.

## Key Architectural Decisions Made

1. **ViewModel Naming Convention:**
   - `ParkingSessionsListViewModel` - Manages collections of sessions (plural "Sessions")
   - `ParkingSessionEventPublisherViewModel` - Publishes events to API (singular "Event")
   - `ParkingSessionEventFormViewModel` - Manages form state for events (singular "Event")

2. **Separation of Concerns:**
   - Split original `ParkingSessionEventViewModel` into three focused ViewModels:
     - List management (CRUD operations)
     - Event publishing (API interactions)
     - Form state (user input/validation)

3. **File Organization:**
   - Feature-based folder structure for better maintainability
   - Clear separation between Views and ViewModels within each feature

4. **Modern Swift Patterns:**
   - Using `@Observable` macro instead of `ObservableObject` + `@Published`
   - Using `@State` to hold ViewModels in views
   - Using `@Bindable` for two-way bindings in subviews
   - All ViewModels marked with `@MainActor` for thread safety