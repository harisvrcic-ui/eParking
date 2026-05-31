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
