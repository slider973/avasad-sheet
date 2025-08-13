BEGIN;


--
-- MIGRATION VERSION FOR time_sheet_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('time_sheet_backend', '20250813212117162', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250813212117162', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
