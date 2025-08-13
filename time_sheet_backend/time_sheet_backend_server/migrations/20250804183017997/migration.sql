BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "timesheet_data" (
    "id" bigserial PRIMARY KEY,
    "validationRequestId" bigint NOT NULL,
    "employeeId" text NOT NULL,
    "employeeName" text NOT NULL,
    "employeeCompany" text NOT NULL,
    "month" bigint NOT NULL,
    "year" bigint NOT NULL,
    "entries" text NOT NULL,
    "totalDays" double precision NOT NULL,
    "totalHours" text NOT NULL,
    "totalOvertimeHours" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "validation_idx" ON "timesheet_data" USING btree ("validationRequestId");
CREATE INDEX "employee_period_idx" ON "timesheet_data" USING btree ("employeeId", "month", "year");


--
-- MIGRATION VERSION FOR time_sheet_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('time_sheet_backend', '20250804183017997', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250804183017997', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
