# Product Overview

## Time Sheet Backend - HeyTalent

A timesheet management application for HeyTalent company that allows employees to track their work hours and managers to validate timesheets with digital signatures.

### Core Features
- **Employee timesheet tracking**: Daily time entry with morning/afternoon periods
- **Manager validation workflow**: Digital signature approval system for timesheets
- **PDF generation**: Automated PDF creation with manager signatures
- **Multi-platform support**: Flutter app for iOS, Android, Web, macOS, and Windows
- **Absence management**: Holiday, sick leave, and vacation tracking
- **Overtime calculation**: Automatic overtime hours computation
- **Apple Watch integration**: Basic time tracking on watchOS

### Current State
The project is undergoing migration from Supabase to Serverpod to reduce hosting costs (~80% cost reduction). The migration maintains all existing functionality while moving to a self-hosted Dart backend solution.

### Target Users
- **Employees**: Track daily work hours, submit timesheets
- **Managers**: Review and approve employee timesheets with digital signatures
- **HR/Admin**: Manage employee data and generate reports

### Business Context
- Company: HeyTalent (Swiss company - locale: fr_CH)
- Industry: Time tracking and workforce management
- Deployment: Self-hosted solution to reduce operational costs