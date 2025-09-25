# Parking Rights Monitor

A SwiftUI iOS application for monitoring and managing parking rights data from external APIs.

## Project Overview

This application is designed to fetch, display, and manage parking rights information from external APIs. Parking rights represent blocks of time when a vehicle has paid for parking at a specific location. The app uses SwiftUI for the user interface and SwiftData for local data persistence.

### What are Parking Rights?
Parking rights are time-based permissions that indicate when a vehicle has paid for parking. Based on the API documentation, each parking right contains the following fields:

#### Core Fields
- **`id`** (string, required): Unique identifier for the parking right
- **`zone_id`** (string, required): The zone that the right applies to
- **`operator_id`** (string, required): The operator that the right applies to
- **`start_time`** (string, required): When the parking right became valid (RFC 3339 UTC)
- **`end_time`** (string, required): When the parking right expires (RFC 3339 UTC)
- **`type`** (string, required): Classification of the parking right's application source
  - Allowed values: `parking`, `permit`
- **`reference_id`** (string, required): Reference identifier from the source application

#### Vehicle Information (when applicable)
- **`vehicle`** (object): Vehicle information for LPN-based zones
  - **`vehicle_plate`** (string): License plate number
  - **`vehicle_state`** (string): State of the license plate

#### Space Information (when applicable)
- **`space_number`** (string): The space number for space-based zones

## Current Project Status

- **Framework**: SwiftUI with SwiftData
- **Target Platform**: iOS (with macOS compatibility)
- **Data Model**: Currently using a basic `Item` model with timestamp
- **UI State**: Basic list view with add/delete functionality (template code)

## Architecture & Data Flow

### Current Structure
```
ParkingRightsMonitor/
├── ParkingRightsMonitorApp.swift    # App entry point with SwiftData container
├── ContentView.swift                # Main UI view (list-based)
├── Item.swift                      # Basic data model
└── Assets.xcassets/                # App icons and assets
```

### Project Organization
*You'll work through organizing the project structure as you learn SwiftUI and iOS development. The current template provides a starting point with SwiftData integration.*

## UI Design Recommendations

### 1. Operator Selection (First Screen)
- **Search Bar**: Find operators by name or ID
- **Operator List**: 
  - Operator name and ID
  - Number of zones/rights (if available)
  - Last updated timestamp
- **Selection**: Tap to select operator and proceed to monitoring

### 2. Zone Selection (Second Screen)
- **Header**: Selected operator name with back button
- **Zone List**: Available zones for the selected operator
- **Search/Filter**: Find zones by name or location
- **Selection**: Tap to select zone and view parking rights

### 3. Parking Rights Monitoring (Main Experience)
- **Header**: Operator > Zone navigation with refresh button
- **Summary Cards**: 
  - Total active rights
  - Expiring soon (next 2 hours)
  - Recently expired
- **Real-time List**: Live monitoring of parking rights
  - Vehicle plate (if available)
  - Time remaining/expired status
  - Space number (if applicable)
  - Visual indicators for status
- **Quick Actions**: Refresh, filter, export

### 4. Parking Right Detail View
- **Header**: Vehicle info and status badge
- **Details Section**:
  - Start/end times with countdown
  - Zone and space information
  - Operator details
- **Actions**: View history, export, share

### 5. Settings View (First to Build)
- **Selected Operator**: Currently selected operator (persistent)
- **API Configuration**: Endpoint URL, authentication
- **Monitoring Settings**: Refresh intervals, alerts
- **Notifications**: Expiration alerts, sync status

## Development Learning Path

### Phase 1: Foundation (Current)
- [x] Basic SwiftUI project setup
- [x] SwiftData integration
- [ ] Create `AppSettings` model for persistent storage
- [ ] Build settings form UI
- [ ] Learn SwiftData basics with settings persistence

### Phase 2: Navigation & Data Models
- [ ] Design `ParkingRight`, `Operator`, and `Zone` data models
- [ ] Implement navigation flow (Operator → Zone → Rights)
- [ ] Create mock data for operators and zones
- [ ] Build basic list views for each level

### Phase 3: Operator Selection UI
- [ ] Build operator list with search functionality
- [ ] Implement operator selection and navigation
- [ ] Add operator details and metadata display
- [ ] Create smooth transitions between screens

### Phase 4: Zone Selection UI
- [ ] Build zone list for selected operator
- [ ] Implement zone filtering and search
- [ ] Add zone selection and navigation
- [ ] Display zone-specific information

### Phase 5: Parking Rights Monitoring
- [ ] Build the main monitoring interface
- [ ] Implement real-time parking rights display
- [ ] Add status indicators and time remaining
- [ ] Create summary cards and metrics

### Phase 6: Enhanced Monitoring Features
- [ ] Add pull-to-refresh functionality
- [ ] Implement auto-refresh for real-time monitoring
- [ ] Add filtering and sorting options
- [ ] Create notification system for expirations

### Phase 7: Polish & Testing
- [ ] Add comprehensive error handling
- [ ] Implement unit tests
- [ ] Add accessibility features
- [ ] Performance optimization

## SwiftUI Learning Focus Areas

### Essential Concepts for Your App
1. **Navigation**: `NavigationView`, `NavigationLink`, `NavigationStack` (iOS 16+)
2. **Lists**: `List`, `ForEach`, `Section`, custom row views
3. **State Management**: `@State`, `@ObservableObject`, `@StateObject`
4. **Data Flow**: `@Binding`, `@Environment`, `@Query`
5. **Search**: `Searchable`, `@State` for search text
6. **Real-time Updates**: `Timer`, `@State` for refresh intervals

### Advanced Topics
1. **Async/Await**: For API calls and data loading
2. **Combine Framework**: For reactive programming
3. **Custom Views**: Reusable components and modifiers
4. **Animations**: Transitions and state changes
5. **Accessibility**: VoiceOver support and semantic labels

## API Integration Strategy

### Recommended Approach
1. **Start with Mock Data**: Create sample parking rights for UI development
2. **Design API Models**: Define response structures before implementation
3. **Implement Network Layer**: Use `URLSession` with async/await
4. **Add Error Handling**: Network failures, parsing errors, user feedback
5. **Implement Caching**: Store data locally for offline access

### API Integration Strategy
*You'll implement API integration when you're ready. The app will make GET requests to fetch parking rights data from an external API. Start with mock data for UI development, then integrate the real API later.*

## Data Model Design

### Data Model Design

Based on the API documentation, your `ParkingRight` model should include these fields:

#### Required Fields
- `id`: String (unique identifier)
- `zone_id`: String (parking zone identifier)
- `operator_id`: String (operator identifier)
- `start_time`: String (RFC 3339 UTC timestamp)
- `end_time`: String (RFC 3339 UTC timestamp)
- `type`: String (either "parking" or "permit")
- `reference_id`: String (source application reference)

#### Optional Fields
- `vehicle`: Object containing:
  - `vehicle_plate`: String (license plate number)
  - `vehicle_state`: String (license plate state)
- `space_number`: String (for space-based zones)

#### Swift Implementation Considerations
- Use `Date` type for `start_time` and `end_time` (convert from RFC 3339 strings)
- Create a `Vehicle` struct for the vehicle object
- Consider using enums for `type` field ("parking" vs "permit")
- Handle optional fields appropriately in your SwiftData model

## Development Guidelines

### Code Organization
- Keep views focused and single-purpose
- Use ViewModels for business logic
- Implement proper error handling
- Follow Swift naming conventions
- Add documentation for complex logic

### Testing Strategy
- Unit tests for business logic
- UI tests for critical user flows
- Mock API responses for consistent testing
- Test error scenarios and edge cases

## Future Enhancements

### Potential Features
- **Map Integration**: Show parking rights on map
- **Push Notifications**: Expiration alerts
- **Document Management**: Attach photos/documents
- **Export Functionality**: Share data in various formats
- **Multi-User Support**: Family/team sharing
- **Analytics**: Usage patterns and insights

### Technical Improvements
- **Core Data Migration**: If SwiftData limitations are reached
- **Background Sync**: Automatic data updates
- **Offline Support**: Full offline functionality
- **Widget Support**: iOS home screen widgets
- **Apple Watch App**: Quick access to parking rights

## Getting Started

1. **Prerequisites**: Xcode 15+, iOS 17+ target
2. **Dependencies**: Currently using only system frameworks
3. **Development**: Open `ParkingRightsMonitor.xcodeproj` in Xcode
4. **Testing**: Use iOS Simulator or physical device

## Contributing

When making changes to this project:

1. **Update this README** with any architectural changes
2. **Document new features** and their purpose
3. **Update the development phases** as you progress
4. **Maintain the learning path** for future reference
5. **Keep the AI assistant context** updated for future development

## AI Assistant Context

### Current Project State (Updated: Latest Conversation)
This is a SwiftUI iOS app for monitoring parking rights from external APIs. The project is in early development with a focus on learning SwiftUI and SwiftData.

**Key Decisions Made:**
- **UI Flow**: Operator Selection → Zone Selection → Parking Rights Monitoring
- **Operator Persistence**: Selected operator should be saved across app sessions
- **Development Approach**: Start with settings form to learn SwiftData basics
- **Monitoring Focus**: The main UI experience centers around real-time parking rights monitoring

**Current Development Phase:**
- Building a settings form as the first feature to learn SwiftData
- Settings will include: selected operator, API endpoint, refresh intervals, notifications
- Using this as a foundation to understand SwiftData before building the main app features

**API Data Structure (Documented):**
Parking rights contain: id, zone_id, operator_id, start_time, end_time, type, reference_id, vehicle (optional), space_number (optional)

**Next Steps:**
1. Create AppSettings SwiftData model
2. Build settings form UI with operator selection
3. Learn SwiftData persistence with settings
4. Use this foundation to build the main operator → zone → monitoring flow

### Instructions for AI Assistants

**When working on this project, follow these guidelines:**

1. **Always read this README first** to understand the current project state and decisions made
2. **Update the README** whenever you make significant changes to:
   - Data models or architecture
   - UI structure or navigation flow
   - New features or functionality
   - Development phases or learning path
3. **Maintain the learning context** - this is a SwiftUI/iOS learning project
4. **Follow the established UI flow**: Operator Selection → Zone Selection → Parking Rights Monitoring
5. **Start with settings form** if the user is beginning development - it's the foundation for learning SwiftData
6. **Keep the AI Assistant Context section updated** with current project state and next steps
7. **Document any new decisions or architectural changes** in the README
8. **Preserve the learning-focused approach** - guide the user through SwiftUI concepts as they build

**Current Priority**: Help the user build a settings form with SwiftData to learn persistence before building the main app features.
