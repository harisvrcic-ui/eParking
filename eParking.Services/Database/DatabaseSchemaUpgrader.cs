using Microsoft.EntityFrameworkCore;

namespace eParking.Services.Database
{
    /// <summary>
    /// Aligns legacy eParking SQL schemas with the current EF model (e.g. adds ParkingLots).
    /// </summary>
    public static class DatabaseSchemaUpgrader
    {
        public static async Task EnsureLegacySchemaAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[ParkingLots]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[ParkingLots] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [Name] nvarchar(200) NOT NULL,
                        [NumberOfSpots] int NOT NULL DEFAULT 0,
                        [Status] int NOT NULL DEFAULT 1,
                        [IsActive] bit NOT NULL DEFAULT 1,
                        [CreatedAt] datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
                        [UpdatedAt] datetime2 NULL,
                        CONSTRAINT [PK_ParkingLots] PRIMARY KEY ([Id])
                    );
                END

                IF OBJECT_ID(N'[dbo].[ParkingZones]', N'U') IS NOT NULL
                BEGIN
                    IF COL_LENGTH('dbo.ParkingZones', 'ParkingLotId') IS NULL
                        ALTER TABLE [dbo].[ParkingZones] ADD [ParkingLotId] int NULL;

                    IF COL_LENGTH('dbo.ParkingZones', 'Description') IS NULL
                        ALTER TABLE [dbo].[ParkingZones] ADD [Description] nvarchar(500) NULL;
                END
                """);
        }

        /// <summary>
        /// Adds Favorites, Notifications and Reviews on databases created before those entities existed
        /// (EnsureCreated does not alter an existing schema).
        /// </summary>
        public static async Task EnsureFeatureTablesAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[FavoriteParkingLots]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[FavoriteParkingLots] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [UserId] int NOT NULL,
                        [ParkingLotId] int NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        CONSTRAINT [PK_FavoriteParkingLots] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_FavoriteParkingLots_MyAppUsers_UserId]
                            FOREIGN KEY ([UserId]) REFERENCES [dbo].[MyAppUsers]([Id]) ON DELETE NO ACTION,
                        CONSTRAINT [FK_FavoriteParkingLots_ParkingLots_ParkingLotId]
                            FOREIGN KEY ([ParkingLotId]) REFERENCES [dbo].[ParkingLots]([Id]) ON DELETE NO ACTION
                    );
                END

                IF OBJECT_ID(N'[dbo].[FavoriteParkingLots]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FavoriteParkingLots_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[FavoriteParkingLots]'))
                    CREATE INDEX [IX_FavoriteParkingLots_ParkingLotId] ON [dbo].[FavoriteParkingLots]([ParkingLotId]);

                IF OBJECT_ID(N'[dbo].[FavoriteParkingLots]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FavoriteParkingLots_UserId_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[FavoriteParkingLots]'))
                    CREATE UNIQUE INDEX [IX_FavoriteParkingLots_UserId_ParkingLotId] ON [dbo].[FavoriteParkingLots]([UserId], [ParkingLotId]);

                IF OBJECT_ID(N'[dbo].[UserNotifications]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[UserNotifications] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [UserId] int NOT NULL,
                        [ReservationId] int NULL,
                        [Title] nvarchar(120) NOT NULL,
                        [Body] nvarchar(500) NOT NULL,
                        [IsRead] bit NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        CONSTRAINT [PK_UserNotifications] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_UserNotifications_MyAppUsers_UserId]
                            FOREIGN KEY ([UserId]) REFERENCES [dbo].[MyAppUsers]([Id]) ON DELETE NO ACTION,
                        CONSTRAINT [FK_UserNotifications_Reservations_ReservationId]
                            FOREIGN KEY ([ReservationId]) REFERENCES [dbo].[Reservations]([Id]) ON DELETE SET NULL
                    );
                END

                IF OBJECT_ID(N'[dbo].[UserNotifications]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_ReservationId' AND object_id = OBJECT_ID(N'[dbo].[UserNotifications]'))
                    CREATE INDEX [IX_UserNotifications_ReservationId] ON [dbo].[UserNotifications]([ReservationId]);

                IF OBJECT_ID(N'[dbo].[UserNotifications]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_UserId' AND object_id = OBJECT_ID(N'[dbo].[UserNotifications]'))
                    CREATE INDEX [IX_UserNotifications_UserId] ON [dbo].[UserNotifications]([UserId]);

                IF OBJECT_ID(N'[dbo].[Reviews]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[Reviews] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [UserId] int NOT NULL,
                        [ParkingLotId] int NOT NULL,
                        [Rating] int NOT NULL,
                        [Comment] nvarchar(1000) NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        [UpdatedAt] datetime2 NULL,
                        CONSTRAINT [PK_Reviews] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_Reviews_MyAppUsers_UserId]
                            FOREIGN KEY ([UserId]) REFERENCES [dbo].[MyAppUsers]([Id]) ON DELETE NO ACTION,
                        CONSTRAINT [FK_Reviews_ParkingLots_ParkingLotId]
                            FOREIGN KEY ([ParkingLotId]) REFERENCES [dbo].[ParkingLots]([Id]) ON DELETE NO ACTION
                    );
                END

                IF OBJECT_ID(N'[dbo].[Reviews]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reviews_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[Reviews]'))
                    CREATE INDEX [IX_Reviews_ParkingLotId] ON [dbo].[Reviews]([ParkingLotId]);

                IF OBJECT_ID(N'[dbo].[Reviews]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reviews_UserId_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[Reviews]'))
                    CREATE UNIQUE INDEX [IX_Reviews_UserId_ParkingLotId] ON [dbo].[Reviews]([UserId], [ParkingLotId]);

                IF OBJECT_ID(N'[dbo].[ParkingLotViewHistories]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[ParkingLotViewHistories] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [UserId] int NOT NULL,
                        [ParkingLotId] int NOT NULL,
                        [ViewCount] int NOT NULL,
                        [LastViewedAt] datetime2 NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        CONSTRAINT [PK_ParkingLotViewHistories] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_ParkingLotViewHistories_MyAppUsers_UserId]
                            FOREIGN KEY ([UserId]) REFERENCES [dbo].[MyAppUsers]([Id]) ON DELETE NO ACTION,
                        CONSTRAINT [FK_ParkingLotViewHistories_ParkingLots_ParkingLotId]
                            FOREIGN KEY ([ParkingLotId]) REFERENCES [dbo].[ParkingLots]([Id]) ON DELETE NO ACTION
                    );
                END

                IF OBJECT_ID(N'[dbo].[ParkingLotViewHistories]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ParkingLotViewHistories_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[ParkingLotViewHistories]'))
                    CREATE INDEX [IX_ParkingLotViewHistories_ParkingLotId] ON [dbo].[ParkingLotViewHistories]([ParkingLotId]);

                IF OBJECT_ID(N'[dbo].[ParkingLotViewHistories]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ParkingLotViewHistories_UserId_ParkingLotId' AND object_id = OBJECT_ID(N'[dbo].[ParkingLotViewHistories]'))
                    CREATE UNIQUE INDEX [IX_ParkingLotViewHistories_UserId_ParkingLotId] ON [dbo].[ParkingLotViewHistories]([UserId], [ParkingLotId]);
                """);
        }

        public static async Task EnsureParkingLotCoordinatesAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[ParkingLots]', N'U') IS NOT NULL
                BEGIN
                    IF COL_LENGTH('dbo.ParkingLots', 'Latitude') IS NULL
                        ALTER TABLE [dbo].[ParkingLots] ADD [Latitude] float NULL;

                    IF COL_LENGTH('dbo.ParkingLots', 'Longitude') IS NULL
                        ALTER TABLE [dbo].[ParkingLots] ADD [Longitude] float NULL;
                END
                """);
        }

        public static async Task EnsureReservationStatusColumnsAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[Reservations]', N'U') IS NOT NULL
                BEGIN
                    IF COL_LENGTH('dbo.Reservations', 'Status') IS NULL
                        ALTER TABLE [dbo].[Reservations] ADD [Status] int NOT NULL CONSTRAINT [DF_Reservations_Status] DEFAULT 1;

                    IF COL_LENGTH('dbo.Reservations', 'StatusChangedAt') IS NULL
                        ALTER TABLE [dbo].[Reservations] ADD [StatusChangedAt] datetime2 NULL;

                    IF COL_LENGTH('dbo.Reservations', 'StatusChangedByUserId') IS NULL
                        ALTER TABLE [dbo].[Reservations] ADD [StatusChangedByUserId] int NULL;

                    IF COL_LENGTH('dbo.Reservations', 'StatusNote') IS NULL
                        ALTER TABLE [dbo].[Reservations] ADD [StatusNote] nvarchar(500) NULL;
                END
                """);
        }

        public static async Task EnsureAccountEnhancementsAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF COL_LENGTH('dbo.MyAppUsers', 'Picture') IS NULL
                    ALTER TABLE [dbo].[MyAppUsers] ADD [Picture] varbinary(max) NULL;

                IF OBJECT_ID(N'[dbo].[PasswordResetTokens]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[PasswordResetTokens] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [UserId] int NOT NULL,
                        [CodeHash] nvarchar(256) NOT NULL,
                        [CodeSalt] nvarchar(64) NOT NULL,
                        [ExpiresAt] datetime2 NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        [IsUsed] bit NOT NULL DEFAULT 0,
                        CONSTRAINT [PK_PasswordResetTokens] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_PasswordResetTokens_MyAppUsers_UserId]
                            FOREIGN KEY ([UserId]) REFERENCES [dbo].[MyAppUsers]([Id]) ON DELETE CASCADE
                    );
                END

                IF OBJECT_ID(N'[dbo].[PasswordResetTokens]', N'U') IS NOT NULL
                   AND COL_LENGTH('dbo.PasswordResetTokens', 'CodeHash') IS NULL
                BEGIN
                    ALTER TABLE [dbo].[PasswordResetTokens] ADD [CodeHash] nvarchar(256) NOT NULL CONSTRAINT [DF_PasswordResetTokens_CodeHash] DEFAULT('');
                    ALTER TABLE [dbo].[PasswordResetTokens] ADD [CodeSalt] nvarchar(64) NOT NULL CONSTRAINT [DF_PasswordResetTokens_CodeSalt] DEFAULT('');
                    UPDATE [dbo].[PasswordResetTokens] SET [IsUsed] = 1;
                    IF COL_LENGTH('dbo.PasswordResetTokens', 'Code') IS NOT NULL
                        ALTER TABLE [dbo].[PasswordResetTokens] DROP COLUMN [Code];
                    ALTER TABLE [dbo].[PasswordResetTokens] DROP CONSTRAINT [DF_PasswordResetTokens_CodeHash];
                    ALTER TABLE [dbo].[PasswordResetTokens] DROP CONSTRAINT [DF_PasswordResetTokens_CodeSalt];
                END

                IF OBJECT_ID(N'[dbo].[PasswordResetTokens]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PasswordResetTokens_UserId' AND object_id = OBJECT_ID(N'[dbo].[PasswordResetTokens]'))
                    CREATE INDEX [IX_PasswordResetTokens_UserId] ON [dbo].[PasswordResetTokens]([UserId]);
                """);
        }

        public static async Task EnsureNewsTableAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[NewsItems]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[NewsItems] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [Title] nvarchar(200) NOT NULL,
                        [Body] nvarchar(2000) NOT NULL,
                        [Image] varbinary(max) NULL,
                        [IsActive] bit NOT NULL DEFAULT 1,
                        [CreatedAt] datetime2 NOT NULL,
                        [UpdatedAt] datetime2 NULL,
                        CONSTRAINT [PK_NewsItems] PRIMARY KEY ([Id])
                    );
                END
                """);
        }

        /// <summary>
        /// Migrates money columns from legacy int/float to decimal(18,2).
        /// </summary>
        public static async Task EnsureDecimalMoneyColumnsAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[ReservationTypes]', N'U') IS NOT NULL
                   AND COL_LENGTH('dbo.ReservationTypes', 'Price') IS NOT NULL
                   AND EXISTS (
                       SELECT 1 FROM sys.columns c
                       JOIN sys.types t ON c.user_type_id = t.user_type_id
                       WHERE c.object_id = OBJECT_ID(N'[dbo].[ReservationTypes]')
                         AND c.name = N'Price'
                         AND t.name IN (N'int', N'bigint', N'smallint', N'tinyint'))
                BEGIN
                    ALTER TABLE [dbo].[ReservationTypes] ALTER COLUMN [Price] decimal(18,2) NOT NULL;
                END

                IF OBJECT_ID(N'[dbo].[Reservations]', N'U') IS NOT NULL
                   AND COL_LENGTH('dbo.Reservations', 'FinalPrice') IS NOT NULL
                   AND EXISTS (
                       SELECT 1 FROM sys.columns c
                       JOIN sys.types t ON c.user_type_id = t.user_type_id
                       WHERE c.object_id = OBJECT_ID(N'[dbo].[Reservations]')
                         AND c.name = N'FinalPrice'
                         AND t.name IN (N'float', N'real', N'int', N'bigint'))
                BEGIN
                    ALTER TABLE [dbo].[Reservations] ALTER COLUMN [FinalPrice] decimal(18,2) NOT NULL;
                END
                """);
        }

        /// <summary>
        /// Ensures each parking spot belongs to its lot through Zone.ParkingLotId (not DisplayNameSearch).
        /// </summary>
        public static async Task EnsureParkingSpotsLinkedViaZoneAsync(ParkingDbContext context)
        {
            var lots = await context.ParkingLots
                .Where(l => l.IsActive)
                .OrderBy(l => l.Id)
                .ToListAsync();

            foreach (var lot in lots)
            {
                var zone = await context.ParkingZones
                    .Where(z => z.ParkingLotId == lot.Id && z.IsActive)
                    .OrderBy(z => z.Id)
                    .FirstOrDefaultAsync();

                if (zone == null)
                {
                    zone = new Parking.ParkingZone
                    {
                        ParkingLotId = lot.Id,
                        Name = "Zona 1",
                        Description = $"Zona za {lot.Name}",
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    };
                    context.ParkingZones.Add(zone);
                    await context.SaveChangesAsync();
                }

                var legacyKey = NormalizeParkingLotKeyForMigration(lot.Name);
                if (legacyKey == null)
                    continue;

                var spotsToRelink = await context.ParkingSpots
                    .Include(s => s.Zone)
                    .Where(s => s.IsActive
                        && (s.DisplayNameSearch == legacyKey
                            || (s.Zone != null && s.Zone.ParkingLotId != lot.Id && s.DisplayNameSearch == legacyKey)))
                    .ToListAsync();

                foreach (var spot in spotsToRelink)
                {
                    spot.ZoneId = zone.Id;
                    spot.DisplayName = lot.Name;
                    spot.UpdatedAt = DateTime.UtcNow;
                }

                await context.SaveChangesAsync();
            }
        }

        private static string? NormalizeParkingLotKeyForMigration(string? name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return null;

            var normalized = name.Trim().ToLowerInvariant()
                .Replace("\u010D", "c").Replace("\u0107", "c")
                .Replace("\u0161", "s").Replace("\u017E", "z").Replace("\u0111", "d");

            if (normalized.Contains("vijecnica")) return "vijecnica";
            if (normalized.Contains("bascarsij") || normalized.Contains("bascar")) return "bascarsija";
            if (normalized.Contains("aria")) return "aria mall";
            return null;
        }

        public static async Task EnsureReservationTypeBillingUnitAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[ReservationTypes]', N'U') IS NOT NULL
                   AND COL_LENGTH('dbo.ReservationTypes', 'BillingUnit') IS NULL
                BEGIN
                    ALTER TABLE [dbo].[ReservationTypes]
                        ADD [BillingUnit] int NOT NULL CONSTRAINT [DF_ReservationTypes_BillingUnit] DEFAULT(0);
                    ALTER TABLE [dbo].[ReservationTypes] DROP CONSTRAINT [DF_ReservationTypes_BillingUnit];
                END
                """);

            // Separate batch: SQL Server validates column names at compile time for the whole batch.
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[ReservationTypes]', N'U') IS NOT NULL
                   AND COL_LENGTH('dbo.ReservationTypes', 'BillingUnit') IS NOT NULL
                BEGIN
                    UPDATE [dbo].[ReservationTypes]
                    SET [BillingUnit] = 1
                    WHERE [BillingUnit] = 0
                      AND (
                          [Name] LIKE N'%daily%' COLLATE SQL_Latin1_General_CP1_CI_AS
                          OR [Name] LIKE N'%dnev%' COLLATE SQL_Latin1_General_CP1_CI_AS
                      );
                END
                """);
        }

        public static async Task EnsureUniqueIntegrityIndexesAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[Cars]', N'U') IS NOT NULL
                BEGIN
                    UPDATE [dbo].[Cars]
                    SET [LicensePlate] = UPPER(LTRIM(RTRIM([LicensePlate])))
                    WHERE [LicensePlate] IS NOT NULL;

                    ;WITH [PlateRanks] AS (
                        SELECT [Id], [LicensePlate],
                               ROW_NUMBER() OVER (PARTITION BY [LicensePlate] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[Cars]
                    )
                    UPDATE [c]
                    SET [LicensePlate] = LEFT([c].[LicensePlate] + N'-' + CAST([c].[Id] AS nvarchar(12)), 20)
                    FROM [dbo].[Cars] AS [c]
                    INNER JOIN [PlateRanks] AS [r] ON [c].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[Brands]', N'U') IS NOT NULL
                BEGIN
                    ;WITH [NameRanks] AS (
                        SELECT [Id], [Name],
                               ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[Brands]
                    )
                    UPDATE [b]
                    SET [Name] = LEFT([b].[Name] + N' (' + CAST([b].[Id] AS nvarchar(12)) + N')', 100)
                    FROM [dbo].[Brands] AS [b]
                    INNER JOIN [NameRanks] AS [r] ON [b].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[Colors]', N'U') IS NOT NULL
                BEGIN
                    ;WITH [NameRanks] AS (
                        SELECT [Id], [Name],
                               ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[Colors]
                    )
                    UPDATE [c]
                    SET [Name] = LEFT([c].[Name] + N' (' + CAST([c].[Id] AS nvarchar(12)) + N')', 100)
                    FROM [dbo].[Colors] AS [c]
                    INNER JOIN [NameRanks] AS [r] ON [c].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[ParkingSpotTypes]', N'U') IS NOT NULL
                BEGIN
                    ;WITH [NameRanks] AS (
                        SELECT [Id], [Name],
                               ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[ParkingSpotTypes]
                    )
                    UPDATE [t]
                    SET [Name] = LEFT([t].[Name] + N' (' + CAST([t].[Id] AS nvarchar(12)) + N')', 100)
                    FROM [dbo].[ParkingSpotTypes] AS [t]
                    INNER JOIN [NameRanks] AS [r] ON [t].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[ReservationTypes]', N'U') IS NOT NULL
                BEGIN
                    ;WITH [NameRanks] AS (
                        SELECT [Id], [Name],
                               ROW_NUMBER() OVER (PARTITION BY [Name] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[ReservationTypes]
                    )
                    UPDATE [t]
                    SET [Name] = LEFT([t].[Name] + N' (' + CAST([t].[Id] AS nvarchar(12)) + N')', 100)
                    FROM [dbo].[ReservationTypes] AS [t]
                    INNER JOIN [NameRanks] AS [r] ON [t].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[ParkingSpots]', N'U') IS NOT NULL
                BEGIN
                    ;WITH [SpotRanks] AS (
                        SELECT [Id], [ZoneId], [ParkingNumber],
                               ROW_NUMBER() OVER (PARTITION BY [ZoneId], [ParkingNumber] ORDER BY [Id]) AS [RowNum]
                        FROM [dbo].[ParkingSpots]
                    )
                    UPDATE [s]
                    SET [ParkingNumber] = [s].[ParkingNumber] + [r].[RowNum] - 1
                    FROM [dbo].[ParkingSpots] AS [s]
                    INNER JOIN [SpotRanks] AS [r] ON [s].[Id] = [r].[Id]
                    WHERE [r].[RowNum] > 1;
                END

                IF OBJECT_ID(N'[dbo].[MyAppUsers]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MyAppUsers_Username' AND object_id = OBJECT_ID(N'[dbo].[MyAppUsers]'))
                    CREATE UNIQUE INDEX [IX_MyAppUsers_Username] ON [dbo].[MyAppUsers]([Username]);

                IF OBJECT_ID(N'[dbo].[MyAppUsers]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MyAppUsers_Email' AND object_id = OBJECT_ID(N'[dbo].[MyAppUsers]'))
                    CREATE UNIQUE INDEX [IX_MyAppUsers_Email] ON [dbo].[MyAppUsers]([Email]);

                IF OBJECT_ID(N'[dbo].[Cars]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Cars_LicensePlate' AND object_id = OBJECT_ID(N'[dbo].[Cars]'))
                    CREATE UNIQUE INDEX [IX_Cars_LicensePlate] ON [dbo].[Cars]([LicensePlate]);

                IF OBJECT_ID(N'[dbo].[ParkingSpots]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ParkingSpots_ZoneId_ParkingNumber' AND object_id = OBJECT_ID(N'[dbo].[ParkingSpots]'))
                    CREATE UNIQUE INDEX [IX_ParkingSpots_ZoneId_ParkingNumber] ON [dbo].[ParkingSpots]([ZoneId], [ParkingNumber]);

                IF OBJECT_ID(N'[dbo].[Brands]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Brands_Name' AND object_id = OBJECT_ID(N'[dbo].[Brands]'))
                    CREATE UNIQUE INDEX [IX_Brands_Name] ON [dbo].[Brands]([Name]);

                IF OBJECT_ID(N'[dbo].[Colors]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Colors_Name' AND object_id = OBJECT_ID(N'[dbo].[Colors]'))
                    CREATE UNIQUE INDEX [IX_Colors_Name] ON [dbo].[Colors]([Name]);

                IF OBJECT_ID(N'[dbo].[ParkingSpotTypes]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ParkingSpotTypes_Name' AND object_id = OBJECT_ID(N'[dbo].[ParkingSpotTypes]'))
                    CREATE UNIQUE INDEX [IX_ParkingSpotTypes_Name] ON [dbo].[ParkingSpotTypes]([Name]);

                IF OBJECT_ID(N'[dbo].[ReservationTypes]', N'U') IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReservationTypes_Name' AND object_id = OBJECT_ID(N'[dbo].[ReservationTypes]'))
                    CREATE UNIQUE INDEX [IX_ReservationTypes_Name] ON [dbo].[ReservationTypes]([Name]);
                """);
        }

        public static async Task LinkOrphanZonesToDefaultLotAsync(ParkingDbContext context, DateTime seedDate)
        {
            var lotId = await context.ParkingLots.Select(l => l.Id).FirstOrDefaultAsync();
            if (lotId == 0)
            {
                context.ParkingLots.Add(new Parking.ParkingLot
                {
                    Name = "Sarajevo",
                    NumberOfSpots = 3,
                    Status = Parking.ParkingLotStatus.Active,
                    IsActive = true,
                    CreatedAt = seedDate
                });
                await context.SaveChangesAsync();
                lotId = await context.ParkingLots.Select(l => l.Id).FirstAsync();
            }

            await context.Database.ExecuteSqlRawAsync(
                "UPDATE [ParkingZones] SET [ParkingLotId] = {0} WHERE [ParkingLotId] IS NULL",
                lotId);
        }
    }
}
