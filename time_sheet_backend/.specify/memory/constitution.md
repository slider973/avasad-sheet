<!--
  Sync Impact Report
  ===================
  Version change: 0.0.0 → 1.0.0 (initial ratification)
  Modified principles: N/A (first version)
  Added sections: 5 principles, Architecture Constraints, Development Workflow, Governance
  Removed sections: N/A
  Templates requiring updates:
    - plan-template.md: ✅ compatible (Constitution Check section exists)
    - spec-template.md: ✅ compatible (priority-based stories align with principles)
    - tasks-template.md: ✅ compatible (story-based grouping matches workflow)
  Follow-up TODOs: none
-->

# TimeSheet Constitution

## Core Principles

### I. Offline-First Data Integrity

All user data (timesheet entries, absences, expenses) MUST be written to the
local SQLite database via PowerSync before any network sync occurs. The app
MUST remain fully functional without internet connectivity. Data conflicts
during sync MUST be resolved deterministically via PowerSync's conflict
resolution rules. No feature may bypass the local-first data flow:
UI → BLoC → UseCase → Repository → PowerSync (SQLite) → PostgreSQL.

### II. Clean Architecture Boundaries

The domain layer (entities, use cases, repository interfaces) MUST NOT import
any infrastructure package (PowerSync, Supabase, Dio, etc.). All external
dependencies MUST be injected through repository interfaces registered in
GetIt. Each feature module MUST follow the `domain/`, `data/`,
`presentation/` directory structure. Violations break testability and
portability.

### III. Row-Level Security as Source of Truth

Every table in PostgreSQL MUST have RLS policies enforced. Data access
boundaries (who sees what) are defined in SQL migrations, NOT in application
code. PowerSync sync rules MUST align with RLS policies. Any schema change
MUST include a corresponding RLS policy update. The application MUST NOT
rely on client-side filtering for data access control.

### IV. Role-Based Multi-Tenancy

The system supports five roles: `employee`, `manager`, `admin`, `org_admin`,
`super_admin`. Navigation, data visibility, and available actions MUST adapt
based on the user's role and organization. Cross-organization data access
MUST only occur through explicit `manager_employees` links. Both the Flutter
app and the React web app MUST enforce consistent role-based behavior.

### V. Incremental Migration Over Rewrites

Legacy components (Isar, Serverpod) MUST be removed incrementally with
backward-compatible migration paths. New features MUST be built on the
current stack (Supabase + PowerSync + Flutter/React). Database schema
changes MUST use numbered migration files (`00NNN_description.sql`).
Breaking changes MUST include a migration strategy in the PR description.

## Architecture Constraints

- **Backend**: Supabase self-hosted (PostgreSQL, GoTrue, Storage, Realtime)
  deployed via Docker Compose on Dokploy. No external BaaS dependencies.
- **Sync**: PowerSync self-hosted for bidirectional offline-first sync.
  Sync rules defined in `powersync.yaml` with three buckets: `user_data`,
  `manager_data`, `org_data`.
- **Mobile/Desktop**: Flutter with BLoC state management, GetIt DI, fpdart
  for functional error handling (`Either<Failure, T>`).
- **Web**: React + TypeScript + Vite + Tailwind + shadcn/ui + TanStack Query.
  Deployed as Docker image on Swarm via GitHub Actions CI/CD.
- **Email**: Resend SMTP via GoTrue for transactional emails. Domain
  `staticflow.ch` with verified SPF/DKIM records.
- **Storage**: Three Supabase Storage buckets (pdfs, signatures, receipts)
  with RLS policies. Accessed via `StorageService`.

## Development Workflow

- **Branching**: Feature branches from `main`. PRs reviewed before merge.
- **Database changes**: New migration file → apply to PostgreSQL → update
  PowerSync sync rules if needed → update Flutter schema → update data layer.
- **Deployment (web)**: Push to `main` triggers GitHub Actions → Docker build
  → push to GHCR → SSH deploy with `docker service update --force` on Swarm.
- **Deployment (mobile)**: Manual builds via `flutter build apk/ios --release`.
- **Testing**: `flutter test` for unit/widget tests. Playwright for web E2E.
  Anomaly detection rules have dedicated test coverage.
- **Code style**: Clean Architecture enforced. No direct infrastructure imports
  in domain layer. French UI strings. No 80-char line limit.

## Governance

- This constitution is the authoritative source for architectural decisions
  and development practices in the TimeSheet project.
- Amendments MUST be documented with a version bump, rationale, and migration
  plan if principles are modified or removed.
- All PRs MUST comply with the principles above. Reviewers MUST verify
  compliance during code review.
- Runtime development guidance is maintained in `CLAUDE.md` at the repo root.
- Complexity MUST be justified. Prefer simple, working solutions over
  speculative abstractions.

**Version**: 1.0.0 | **Ratified**: 2026-04-04 | **Last Amended**: 2026-04-04
