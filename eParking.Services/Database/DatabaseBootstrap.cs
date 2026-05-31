using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eParking.Services.Database;

/// <summary>
/// Waits for SQL Server (Docker) and applies schema + seed without crashing on transient errors.
/// </summary>
public static class DatabaseBootstrap
{
    public const int MaxAttempts = 30;
    public static readonly TimeSpan DelayBetweenAttempts = TimeSpan.FromSeconds(2);

    public static async Task InitializeAsync(ParkingDbContext db, ILogger logger)
    {
        Exception? lastError = null;

        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                // CanConnectAsync returns false when the catalog (e.g. 200146) does not exist yet.
                // EnsureCreated creates the database and schema when the server is reachable.
                await db.Database.EnsureCreatedAsync();
                await DatabaseSeeder.SeedAsync(db);
                logger.LogInformation("Database initialized (attempt {Attempt}).", attempt);
                return;
            }
            catch (Exception ex)
            {
                lastError = ex;
                logger.LogWarning(
                    ex,
                    "Database init attempt {Attempt}/{Max} failed.",
                    attempt,
                    MaxAttempts);
                await Task.Delay(DelayBetweenAttempts);
            }
        }

        throw new InvalidOperationException(
            "Database could not be initialized after multiple attempts. " +
            "Ensure SQL Server is running and the connection string is correct.",
            lastError);
    }
}
