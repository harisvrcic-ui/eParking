using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eParking.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddParkingLotViewHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ParkingLotViewHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ParkingLotId = table.Column<int>(type: "int", nullable: false),
                    ViewCount = table.Column<int>(type: "int", nullable: false),
                    LastViewedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParkingLotViewHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ParkingLotViewHistories_MyAppUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "MyAppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ParkingLotViewHistories_ParkingLots_ParkingLotId",
                        column: x => x.ParkingLotId,
                        principalTable: "ParkingLots",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ParkingLotViewHistories_ParkingLotId",
                table: "ParkingLotViewHistories",
                column: "ParkingLotId");

            migrationBuilder.CreateIndex(
                name: "IX_ParkingLotViewHistories_UserId_ParkingLotId",
                table: "ParkingLotViewHistories",
                columns: new[] { "UserId", "ParkingLotId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ParkingLotViewHistories");
        }
    }
}
