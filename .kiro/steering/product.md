# Product Overview

**Time Sheet** is a Flutter mobile application designed for HeyTalent that manages employee time tracking. The application allows employees to clock in/out, track breaks, and visualize work time with an elegant timer interface.

## Key Features
- Employee time tracking with clock in/out functionality
- Break time management
- Elegant timer interface with clock-style visualization
- PDF timesheet generation and validation workflow
- Manager signature system for timesheet approval
- Multi-platform support (iOS, Android, Desktop, Web)

## Current Architecture
The project is migrating from Supabase to Serverpod to reduce hosting costs and gain infrastructure control. The system consists of:
- **Flutter App**: Main mobile application for employees
- **Serverpod Backend**: Self-hosted backend server (migration in progress)
- **Validation System**: Manager approval workflow with digital signatures
- **PDF Processing**: Automated PDF generation and signature integration

## Target Users
- **Employees**: Time tracking and timesheet submission
- **Managers**: Timesheet validation and approval
- **HR/Admin**: Time management oversight

The application is specifically built for HeyTalent's workforce management needs.