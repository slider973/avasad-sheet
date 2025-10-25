# Implementation Plan

- [ ] 1. Set up service dependencies and injection
  - Inject UnifiedOvertimeCalculator service into GeneratePdfUseCase
  - Add UserPreferences service dependency for configuration access
  - Create PdfCalculationContext class to hold calculation dependencies
  - _Requirements: 1.1, 3.1, 3.2, 3.3_

- [ ] 2. Refactor weekly overtime calculation logic
  - [ ] 2.1 Create enhanced WeekData model with compensated overtime field
    - Add compensatedWeeklyOvertime field to track properly calculated weekly totals
    - Modify week grouping logic to use UnifiedOvertimeCalculator for each week
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 2.2 Update _buildWeekTable method to use compensated totals
    - Modify weekly table generation to display compensated overtime totals
    - Ensure weekly totals match UI calculations exactly
    - Preserve existing table formatting and layout
    - _Requirements: 2.1, 2.2, 4.1, 4.2_

- [ ] 3. Fix monthly total calculation
  - [ ] 3.1 Replace raw overtime summation with weekly total summation
    - Modify totalOvertimeHours calculation to sum compensated weekly totals
    - Remove direct overtimeByDay.values.fold() calculation
    - _Requirements: 1.1, 1.2_

  - [ ] 3.2 Update _buildSummaryTable to use corrected monthly total
    - Ensure summary table displays the corrected monthly overtime total
    - Verify consistency with UI monthly totals
    - _Requirements: 1.1, 1.4_

- [ ] 4. Implement configuration integration
  - [ ] 4.1 Add user preference loading in PDF generation
    - Load normal hours threshold from user preferences
    - Load monthly compensation settings
    - Load weekend overtime configuration
    - _Requirements: 3.1, 3.2, 3.3_

  - [ ] 4.2 Apply user-specific overtime calculation rules
    - Pass user preferences to UnifiedOvertimeCalculator
    - Respect per-day overtime exceptions in PDF calculations
    - _Requirements: 3.4, 2.3_

- [ ] 5. Add error handling and fallback mechanisms
  - [ ] 5.1 Implement calculation error handling
    - Add try-catch blocks around UnifiedOvertimeCalculator calls
    - Implement fallback to original calculation method if service fails
    - Add logging for calculation errors and discrepancies
    - _Requirements: 6.1, 6.2_

  - [ ] 5.2 Add configuration validation
    - Validate user preferences before PDF generation
    - Use system defaults if preferences are unavailable
    - Handle missing or invalid configuration gracefully
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 6. Create comprehensive test coverage
  - [ ] 6.1 Write unit tests for calculation consistency
    - Test PDF totals match UI totals for identical data sets
    - Test various overtime scenarios (weekend work, monthly compensation)
    - Test edge cases (empty weeks, partial weeks, month boundaries)
    - _Requirements: 1.2, 2.1, 2.2, 2.3_

  - [ ] 6.2 Write integration tests for service dependencies
    - Test UnifiedOvertimeCalculator integration in PDF context
    - Test UserPreferences service integration
    - Test end-to-end PDF generation with corrected calculations
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ] 6.3 Add validation tests comparing old vs new calculations
    - Create tests that compare original calculation with corrected calculation
    - Verify that corrected calculation matches UI calculations
    - Test with real user data scenarios
    - _Requirements: 1.1, 1.2, 5.1, 5.2_

- [ ] 7. Performance optimization and monitoring
  - [ ] 7.1 Optimize calculation performance
    - Profile PDF generation performance with new calculation logic
    - Optimize UnifiedOvertimeCalculator calls if needed
    - Ensure PDF generation time remains acceptable
    - _Requirements: 6.4_

  - [ ] 7.2 Add calculation monitoring and logging
    - Log calculation differences during development/testing
    - Add performance metrics for PDF generation
    - Implement validation logging for production monitoring
    - _Requirements: 6.5_

- [ ] 8. Final integration and validation
  - [ ] 8.1 Integrate all components and test end-to-end functionality
    - Verify complete PDF generation pipeline works correctly
    - Test with various user configurations and data scenarios
    - Ensure backward compatibility and no breaking changes
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 8.2 Validate calculation accuracy across all scenarios
    - Compare PDF calculations with UI calculations for consistency
    - Test with edge cases and complex overtime scenarios
    - Verify manager validation workflow still works correctly
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2, 5.3_