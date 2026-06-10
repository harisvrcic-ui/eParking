using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eParking.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddBillingUnitToReservationType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "BillingUnit",
                table: "ReservationTypes",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.Sql("""
                UPDATE [ReservationTypes]
                SET [BillingUnit] = 1
                WHERE [BillingUnit] = 0
                  AND (
                      [Name] LIKE N'%daily%' COLLATE SQL_Latin1_General_CP1_CI_AS
                      OR [Name] LIKE N'%dnev%' COLLATE SQL_Latin1_General_CP1_CI_AS
                  );
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BillingUnit",
                table: "ReservationTypes");
        }
    }
}
