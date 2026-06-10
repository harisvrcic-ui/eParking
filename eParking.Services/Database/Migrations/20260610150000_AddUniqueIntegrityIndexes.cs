using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eParking.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddUniqueIntegrityIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
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
                """);

            migrationBuilder.CreateIndex(
                name: "IX_MyAppUsers_Username",
                table: "MyAppUsers",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MyAppUsers_Email",
                table: "MyAppUsers",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cars_LicensePlate",
                table: "Cars",
                column: "LicensePlate",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ParkingSpots_ZoneId_ParkingNumber",
                table: "ParkingSpots",
                columns: new[] { "ZoneId", "ParkingNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Brands_Name",
                table: "Brands",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Colors_Name",
                table: "Colors",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ParkingSpotTypes_Name",
                table: "ParkingSpotTypes",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ReservationTypes_Name",
                table: "ReservationTypes",
                column: "Name",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ReservationTypes_Name",
                table: "ReservationTypes");

            migrationBuilder.DropIndex(
                name: "IX_ParkingSpotTypes_Name",
                table: "ParkingSpotTypes");

            migrationBuilder.DropIndex(
                name: "IX_Colors_Name",
                table: "Colors");

            migrationBuilder.DropIndex(
                name: "IX_Brands_Name",
                table: "Brands");

            migrationBuilder.DropIndex(
                name: "IX_ParkingSpots_ZoneId_ParkingNumber",
                table: "ParkingSpots");

            migrationBuilder.DropIndex(
                name: "IX_Cars_LicensePlate",
                table: "Cars");

            migrationBuilder.DropIndex(
                name: "IX_MyAppUsers_Email",
                table: "MyAppUsers");

            migrationBuilder.DropIndex(
                name: "IX_MyAppUsers_Username",
                table: "MyAppUsers");
        }
    }
}
