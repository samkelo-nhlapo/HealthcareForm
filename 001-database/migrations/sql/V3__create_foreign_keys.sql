-- V3__create_foreign_keys.sql
-- Idempotent FK creation script. Run after all referenced tables exist.
-- Move ALTER TABLE ... ADD CONSTRAINT FK_... statements here. Use IF NOT EXISTS guards.

-- Example pattern:
-- IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Provinces_Country')
-- BEGIN
--   ALTER TABLE [Location].[Provinces] WITH CHECK ADD CONSTRAINT FK_Provinces_Country FOREIGN KEY([CountryIDFK])
--   REFERENCES [Location].[Countries] ([CountryId])
-- END
-- GO

PRINT 'V3 placeholder: add foreign key creation DDL here.'
