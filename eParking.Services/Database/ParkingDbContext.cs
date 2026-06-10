using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services.Database
{
    public class ParkingDbContext : DbContext
    {
        public ParkingDbContext(DbContextOptions<ParkingDbContext> options) : base(options)
        {
        }

        public DbSet<ParkingLot> ParkingLots => Set<ParkingLot>();
        public DbSet<ParkingZone> ParkingZones => Set<ParkingZone>();
        public DbSet<ParkingSpot> ParkingSpots => Set<ParkingSpot>();
        public DbSet<ParkingSpotType> ParkingSpotTypes => Set<ParkingSpotType>();
        public DbSet<Reservation> Reservations => Set<Reservation>();
        public DbSet<ReservationType> ReservationTypes => Set<ReservationType>();
        public DbSet<MyAppUser> MyAppUsers => Set<MyAppUser>();
        public DbSet<Car> Cars => Set<Car>();
        public DbSet<Brand> Brands => Set<Brand>();
        public DbSet<Color> Colors => Set<Color>();
        public DbSet<Gender> Genders => Set<Gender>();
        public DbSet<City> Cities => Set<City>();
        public DbSet<Country> Countries => Set<Country>();
        public DbSet<FavoriteParkingLot> FavoriteParkingLots => Set<FavoriteParkingLot>();
        public DbSet<UserNotification> UserNotifications => Set<UserNotification>();
        public DbSet<Review> Reviews => Set<Review>();
        public DbSet<ParkingLotViewHistory> ParkingLotViewHistories => Set<ParkingLotViewHistory>();
        public DbSet<NewsItem> NewsItems => Set<NewsItem>();
        public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<City>()
                .HasOne(c => c.Country)
                .WithMany(co => co.Cities)
                .HasForeignKey(c => c.CountryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingZone>()
                .HasOne(z => z.ParkingLot)
                .WithMany(l => l.Zones)
                .HasForeignKey(z => z.ParkingLotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingSpot>()
                .HasOne(s => s.Zone)
                .WithMany(z => z.ParkingSpots)
                .HasForeignKey(s => s.ZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<FavoriteParkingLot>()
                .HasIndex(x => new { x.UserId, x.ParkingLotId })
                .IsUnique();

            modelBuilder.Entity<FavoriteParkingLot>()
                .HasOne(x => x.User)
                .WithMany(u => u.FavoriteParkingLots)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<FavoriteParkingLot>()
                .HasOne(x => x.ParkingLot)
                .WithMany(l => l.Favorites)
                .HasForeignKey(x => x.ParkingLotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserNotification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserNotification>()
                .HasOne(n => n.Reservation)
                .WithMany()
                .HasForeignKey(n => n.ReservationId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Review>()
                .HasIndex(r => new { r.UserId, r.ParkingLotId })
                .IsUnique();

            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.ParkingLot)
                .WithMany(l => l.Reviews)
                .HasForeignKey(r => r.ParkingLotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingLotViewHistory>()
                .HasIndex(x => new { x.UserId, x.ParkingLotId })
                .IsUnique();

            modelBuilder.Entity<ParkingLotViewHistory>()
                .HasOne(x => x.User)
                .WithMany(u => u.ViewHistories)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingLotViewHistory>()
                .HasOne(x => x.ParkingLot)
                .WithMany(l => l.ViewHistories)
                .HasForeignKey(x => x.ParkingLotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ReservationType>()
                .Property(t => t.Price)
                .HasColumnType("decimal(18,2)");

            modelBuilder.Entity<Reservation>()
                .Property(r => r.FinalPrice)
                .HasColumnType("decimal(18,2)");
        }
    }
}
