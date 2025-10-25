# Design Document - PDF Overtime Calculation Fix

## Overview

This design addresses the critical issue in PDF timesheet generation where the monthly overtime total is incorrectly calculated by summing raw daily overtime hours instead of weekly totals. The solution involves refactoring the PDF generation logic to reuse the existing UnifiedOvertimeCalculator service, ensuring consistency between the UI and PDF reports.

## Architecture

### Current Architecture Problem
```
PDF Generation (generate_pdf_usecase.dart)
├── Calculates raw overtime per day: overtimeByDay.values.fold()
├── Sums all daily overtime directly
└── Ignores weekly compensation logic
```

### Target Architecture
```
PDF Generation (generate_pdf_usecase.dart)
├── Uses UnifiedOvertimeCalculator service
├── Calculates weekly totals with proper compensation
├── Sums weekly totals for monthly total
└── Maintains consistency with UI calculations
```

## Components and Interfaces

### 1. Modified PDF Generation Service

**File:** `lib/features/pointage/domain/use_cases/generate_pdf_usecase.dart`

**Key Changes:**
- Replace direct overtime calculation with UnifiedOvertimeCalculator usage
- Modify `_buildMonthContent` method to calculate weekly totals first
- Update monthly total calculation to sum weekly totals instead of daily raw overtime

**New Dependencies:**
- `UnifiedOvertimeCalculator` service
- User preference settings for overtime configuration

### 2. Weekly Total Calculation Integration

**Interface:**
```dart
class WeeklyOvertimeTotal {
  final Duration weeklyOvertime;
  final Duration compensatedOvertime;
  final List<DateTime> weekDays;
  final bool hasWeekendWork;
}
```

**Calculation Flow:**
1. Group timesheet entries by week
2. For each week, use UnifiedOvertimeCalculator to get compensated total
3. Sum all weekly compensated totals for monthly total

### 3. Configuration Integration

**Required Settings:**
- Normal hours threshold (from user preferences)
- Monthly compensation enabled/disabled
- Weekend overtime configuration
- Per-day overtime exceptions

## Data Models

### Enhanced Week Structure
```dart
class WeekData {
  final List<DateTime> days;
  final List<TimesheetEntry> entries;
  final Duration rawWeeklyOvertime;
  final Duration compensatedWeeklyOvertime; // NEW
  final Map<DateTime, Duration> dailyOvertime;
}
```

### PDF Calculation Context
```dart
class PdfCalculationContext {
  final User user;
  final List<TimesheetEntry> entries;
  final UnifiedOvertimeCalculator calculator; // NEW
  final UserPreferences preferences; // NEW
}
```

## Error Handling

### Calculation Errors
- **Fallback Strategy:** If UnifiedOvertimeCalculator fails, fall back to current calculation method
- **Logging:** Log calculation discrepancies for debugging
- **Validation:** Compare old vs new calculation methods during transition

### Configuration Errors
- **Default Values:** Use system defaults if user preferences are unavailable
- **Validation:** Ensure configuration consistency before PDF generation

### Data Integrity
- **Entry Validation:** Verify timesheet entries are complete before calculation
- **Date Range Validation:** Ensure all entries fall within the requested month

## Testing Strategy

### Unit Tests
1. **Calculation Consistency Tests**
   - Verify PDF totals match UI totals for same data
   - Test various overtime scenarios (weekend, monthly compensation, etc.)
   - Validate weekly total calculations

2. **Configuration Integration Tests**
   - Test with different user preference combinations
   - Verify fallback behavior when preferences are missing

3. **Edge Case Tests**
   - Empty weeks, partial weeks
   - Month boundaries, leap years
   - Mixed overtime/normal time scenarios

### Integration Tests
1. **End-to-End PDF Generation**
   - Generate PDF and verify all totals
   - Compare with UI calculations
   - Test with real user data scenarios

2. **Service Integration**
   - Test UnifiedOvertimeCalculator integration
   - Verify preference service integration

### Performance Tests
- Measure PDF generation time impact
- Ensure calculation efficiency for large datasets

## Implementation Plan

### Phase 1: Service Integration
- Inject UnifiedOvertimeCalculator into PDF generation
- Add preference service dependency
- Create calculation context structure

### Phase 2: Weekly Calculation Refactor
- Modify week grouping logic to calculate compensated totals
- Update weekly table generation to use new totals
- Preserve existing PDF layout and formatting

### Phase 3: Monthly Total Fix
- Replace raw overtime summation with weekly total summation
- Update summary table generation
- Ensure backward compatibility

### Phase 4: Validation and Testing
- Add comprehensive test coverage
- Implement calculation validation
- Performance optimization if needed

## Migration Strategy

### Backward Compatibility
- Maintain existing PDF structure and appearance
- Preserve all existing functionality
- Ensure no breaking changes to PDF API

### Rollout Plan
1. **Development Testing:** Extensive testing with various data scenarios
2. **Staging Validation:** Compare old vs new calculations
3. **Gradual Rollout:** Monitor for calculation discrepancies
4. **Full Deployment:** Complete migration to new calculation method

## Risk Mitigation

### Calculation Accuracy Risks
- **Mitigation:** Extensive testing with real data
- **Validation:** Side-by-side comparison during development
- **Monitoring:** Log calculation differences during transition

### Performance Risks
- **Mitigation:** Optimize calculation algorithms
- **Monitoring:** Track PDF generation performance
- **Fallback:** Maintain simple calculation as backup

### User Experience Risks
- **Mitigation:** Maintain identical PDF appearance
- **Testing:** Verify all PDF features work correctly
- **Communication:** Document changes for support team