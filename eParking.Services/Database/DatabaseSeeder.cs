using System.Text;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services.Database
{
    public static class DatabaseSeeder
    {
        private const string DefaultPhoneNumber = "+38761000000";
        private const string WwwRootFolder = "wwwroot";

        public static async Task SeedAsync(ParkingDbContext context)
        {
            var seedDate = new DateTime(2026, 11, 1, 0, 0, 0, DateTimeKind.Utc);

            await EnsureCountriesTableAsync(context);
            await DatabaseSchemaUpgrader.EnsureLegacySchemaAsync(context);
            await DatabaseSchemaUpgrader.EnsureFeatureTablesAsync(context);
            await DatabaseSchemaUpgrader.EnsureParkingLotCoordinatesAsync(context);
            await DatabaseSchemaUpgrader.EnsureReservationStatusColumnsAsync(context);
            await DatabaseSchemaUpgrader.EnsureNewsTableAsync(context);
            await DatabaseSchemaUpgrader.EnsureAccountEnhancementsAsync(context);
            await DatabaseSchemaUpgrader.EnsureDecimalMoneyColumnsAsync(context);
            await DatabaseSchemaUpgrader.EnsureReservationTypeBillingUnitAsync(context);
            await BackfillReservationStatusesAsync(context);
            await SeedCountriesAsync(context, seedDate);

            if (!await context.Genders.AnyAsync())
            {
                context.Genders.AddRange(
                    new Gender { Name = "Male", IsActive = true, CreatedAt = seedDate },
                    new Gender { Name = "Female", IsActive = true, CreatedAt = seedDate }
                );
                await context.SaveChangesAsync();
            }

            if (!await context.Cities.AnyAsync())
            {
                context.Cities.AddRange(await GetSeedCitiesAsync(context, seedDate));
                await context.SaveChangesAsync();
            }

            if (!await context.Brands.AnyAsync())
            {
                context.Brands.AddRange(
                    new Brand
                    {
                        Name = "Mercedes-Benz",
                        Logo = ToSeedImageBytes("1.png"),
                        IsActive = true,
                        CreatedAt = seedDate
                    },
                    new Brand
                    {
                        Name = "BMW",
                        Logo = ToSeedImageBytes("2.png"),
                        IsActive = true,
                        CreatedAt = seedDate
                    },
                    new Brand
                    {
                        Name = "Volkswagen",
                        Logo = ToSeedImageBytes("3.png"),
                        IsActive = true,
                        CreatedAt = seedDate
                    }
                );
                await context.SaveChangesAsync();
            }
            else
            {
                await EnsureBrandLogosAsync(context);
            }

            if (!await context.Colors.AnyAsync())
            {
                context.Colors.Add(new Color
                {
                    Name = "Blue",
                    HexCode = "#0000FF",
                    CreatedAt = seedDate
                });
                await context.SaveChangesAsync();
            }

            if (!await context.ParkingSpotTypes.AnyAsync())
            {
                context.ParkingSpotTypes.AddRange(
                    new ParkingSpotType { Name = "Regular", Description = "Regular parking space", PriceMultiplier = 1.0m, CreatedAt = seedDate },
                    new ParkingSpotType { Name = "Disabled", Description = "Accessible parking", PriceMultiplier = 0.5m, CreatedAt = seedDate },
                    new ParkingSpotType { Name = "Compact", Description = "Compact vehicle spot", PriceMultiplier = 0.9m, CreatedAt = seedDate },
                    new ParkingSpotType { Name = "Electric", Description = "Electric vehicle charging spot", PriceMultiplier = 1.3m, CreatedAt = seedDate },
                    new ParkingSpotType { Name = "Large", Description = "Large vehicle spot", PriceMultiplier = 1.2m, CreatedAt = seedDate }
                );
                await context.SaveChangesAsync();
            }

            if (!await context.ReservationTypes.AnyAsync())
            {
                context.ReservationTypes.Add(new ReservationType
                {
                    Name = "Hourly",
                    Price = 5.00m,
                    BillingUnit = Model.BillingUnit.Hourly,
                    CreatedAt = seedDate
                });
                await context.SaveChangesAsync();
            }

            await DatabaseSchemaUpgrader.LinkOrphanZonesToDefaultLotAsync(context, seedDate);
            await EnsureParkinziAndZonesAsync(context, seedDate);

            if (!await context.MyAppUsers.AnyAsync())
            {
                var maleId = await context.Genders.Where(g => g.Name == "Male").Select(g => g.Id).FirstAsync();
                var mostarId = await context.Cities.Where(c => c.Name == "Mostar").Select(c => c.Id).FirstAsync();
                var sarajevoId = await context.Cities.Where(c => c.Name == "Sarajevo").Select(c => c.Id).FirstAsync();

                var (adminSalt, adminHash) = PasswordHasher.CreateSeedHash("admin", "admin");
                var (userSalt, userHash) = PasswordHasher.CreateSeedHash("user", "user");
                var (harisSalt, harisHash) = PasswordHasher.CreateSeedHash("haris", "haris");

                context.MyAppUsers.AddRange(
                    new MyAppUser
                    {
                        FirstName = "Denis",
                        LastName = "Mu�ic",
                        Email = "example1@gmail.com",
                        Username = "admin",
                        PasswordHash = adminHash,
                        PasswordSalt = adminSalt,
                        IsActive = true,
                        CreatedAt = seedDate,
                        PhoneNumber = DefaultPhoneNumber,
                        GenderId = maleId,
                        CityId = mostarId,
                        IsAdmin = true,
                        IsUser = false
                    },
                    new MyAppUser
                    {
                        FirstName = "Adil",
                        LastName = "Joldic",
                        Email = "example2@gmail.com",
                        Username = "user",
                        PasswordHash = userHash,
                        PasswordSalt = userSalt,
                        IsActive = true,
                        CreatedAt = seedDate,
                        PhoneNumber = DefaultPhoneNumber,
                        GenderId = maleId,
                        CityId = mostarId,
                        IsAdmin = false,
                        IsUser = true
                    },
                    new MyAppUser
                    {
                        FirstName = "Haris",
                        LastName = "Vrcic",
                        Email = "haris.vrcic@edu.fit.com",
                        Username = "haris",
                        PasswordHash = harisHash,
                        PasswordSalt = harisSalt,
                        IsActive = true,
                        CreatedAt = seedDate,
                        PhoneNumber = DefaultPhoneNumber,
                        GenderId = maleId,
                        CityId = sarajevoId,
                        IsAdmin = false,
                        IsUser = true
                    }
                );
                await context.SaveChangesAsync();
            }

            if (!await context.Cars.AnyAsync())
            {
                var vwId = await context.Brands.Where(b => b.Name == "Volkswagen").Select(b => b.Id).FirstAsync();
                var bmwId = await context.Brands.Where(b => b.Name == "BMW").Select(b => b.Id).FirstAsync();
                var blueId = await context.Colors.Where(c => c.Name == "Blue").Select(c => c.Id).FirstAsync();
                var adminId = await context.MyAppUsers.Where(u => u.Username == "admin").Select(u => u.Id).FirstAsync();
                var userId = await context.MyAppUsers.Where(u => u.Username == "user").Select(u => u.Id).FirstAsync();
                var harisId = await context.MyAppUsers.Where(u => u.Username == "haris").Select(u => u.Id).FirstAsync();

                context.Cars.AddRange(
                    new Car
                    {
                        BrandId = vwId,
                        ColorId = blueId,
                        UserId = adminId,
                        Model = "Golf 7",
                        LicensePlate = "E12-K-345",
                        YearOfManufacture = 2018,
                        Picture = ToSeedImageBytes("golf7.jpg"),
                        IsActive = true,
                        CreatedAt = seedDate
                    },
                    new Car
                    {
                        BrandId = bmwId,
                        ColorId = blueId,
                        UserId = harisId,
                        Model = "X6",
                        LicensePlate = "021-A-356",
                        YearOfManufacture = 2020,
                        Picture = ToSeedImageBytes("bmw-x6.jpg"),
                        IsActive = true,
                        CreatedAt = seedDate
                    },
                    new Car
                    {
                        BrandId = vwId,
                        ColorId = blueId,
                        UserId = userId,
                        Model = "Passat 8",
                        LicensePlate = "E11-K-111",
                        YearOfManufacture = 2019,
                        Picture = ToSeedImageBytes("passat8.jpg"),
                        IsActive = true,
                        CreatedAt = seedDate
                    }
                );
                await context.SaveChangesAsync();
            }
            else
            {
                await EnsureCarPicturesAsync(context);
            }

            await EnsureDevelopmentCredentialsAsync(context);
            await EnsureRs2StandardUsersAsync(context);

            if (!await context.Reservations.AnyAsync())
            {
                var carId = await context.Cars
                    .Where(c => c.LicensePlate == "E12-K-345")
                    .Select(c => c.Id)
                    .FirstOrDefaultAsync();
                var spotId = await context.ParkingSpots
                    .Where(s => s.DisplayName == "Vijecnica")
                    .Select(s => s.Id)
                    .FirstOrDefaultAsync();
                var typeId = await context.ReservationTypes
                    .Where(t => t.Name == "Hourly")
                    .Select(t => t.Id)
                    .FirstOrDefaultAsync();

                if (carId != 0 && spotId != 0 && typeId != 0)
                {
                    context.Reservations.Add(new Reservation
                    {
                        CarId = carId,
                        ParkingSpotId = spotId,
                        ReservationTypeId = typeId,
                        StartDate = new DateTime(2025, 1, 10, 8, 0, 0, DateTimeKind.Utc),
                        EndDate = new DateTime(2025, 1, 10, 10, 0, 0, DateTimeKind.Utc),
                        FinalPrice = 5.00m,
                        Status = (int)Model.ReservationStatus.Completed,
                        StatusChangedAt = seedDate,
                        StatusNote = "Seed rezervacija (zavr�ena).",
                        CreatedAt = seedDate
                    });
                    await context.SaveChangesAsync();
                }
            }

            // Favorites + Notifications (RS2: dodatne glavne tabele sa seed podacima)
            if (!await context.FavoriteParkingLots.AnyAsync())
            {
                var userId = await context.MyAppUsers.Where(u => u.Username == "user").Select(u => u.Id).FirstAsync();
                var harisId = await context.MyAppUsers.Where(u => u.Username == "haris").Select(u => u.Id).FirstAsync();
                var vijeId = await context.ParkingLots.Where(l => l.Name == "Vijecnica").Select(l => l.Id).FirstOrDefaultAsync();
                var ariaId = await context.ParkingLots.Where(l => l.Name == "Aria Mall").Select(l => l.Id).FirstOrDefaultAsync();

                if (vijeId != 0)
                    context.FavoriteParkingLots.Add(new FavoriteParkingLot { UserId = userId, ParkingLotId = vijeId, CreatedAt = seedDate });
                if (ariaId != 0)
                    context.FavoriteParkingLots.Add(new FavoriteParkingLot { UserId = harisId, ParkingLotId = ariaId, CreatedAt = seedDate });

                await context.SaveChangesAsync();
            }

            if (!await context.UserNotifications.AnyAsync())
            {
                var userId = await context.MyAppUsers.Where(u => u.Username == "user").Select(u => u.Id).FirstAsync();
                var harisId = await context.MyAppUsers.Where(u => u.Username == "haris").Select(u => u.Id).FirstAsync();
                var reservationId = await context.Reservations.Select(r => r.Id).FirstOrDefaultAsync();

                context.UserNotifications.AddRange(
                    new UserNotification
                    {
                        UserId = userId,
                        ReservationId = reservationId == 0 ? null : reservationId,
                        Title = "Rezervacija potvrdena",
                        Body = "Va�a rezervacija je uspje�no potvrdena.",
                        IsRead = false,
                        CreatedAt = seedDate
                    },
                    new UserNotification
                    {
                        UserId = harisId,
                        ReservationId = null,
                        Title = "Dobrodo�li u eParking",
                        Body = "Dodajte omiljene parkinge i pratite obavje�tenja ovdje.",
                        IsRead = false,
                        CreatedAt = seedDate
                    }
                );
                await context.SaveChangesAsync();
            }

            if (!await context.NewsItems.AnyAsync())
            {
                var newsImage = LoadSeedImageFile("1.png");
                context.NewsItems.AddRange(
                    new NewsItem
                    {
                        Title = "Besplatna prva sat parkinga",
                        Body = "Rezervisi parking preko eParking aplikacije i ostvari popust na prvi sat u odabranim lokacijama.",
                        Image = newsImage,
                        IsActive = true,
                        CreatedAt = seedDate
                    },
                    new NewsItem
                    {
                        Title = "Novi parking Aria mall",
                        Body = "Dostupna su nova mjesta u zoni Aria mall. Provjeri dostupnost u aplikaciji.",
                        Image = newsImage,
                        IsActive = true,
                        CreatedAt = seedDate.AddDays(-2)
                    }
                );
                await context.SaveChangesAsync();
            }

            if (!await context.Reviews.AnyAsync())
            {
                var userId = await context.MyAppUsers.Where(u => u.Username == "user").Select(u => u.Id).FirstAsync();
                var harisId = await context.MyAppUsers.Where(u => u.Username == "haris").Select(u => u.Id).FirstAsync();
                var vijeId = await context.ParkingLots.Where(l => l.Name == "Vijecnica").Select(l => l.Id).FirstOrDefaultAsync();
                var ariaId = await context.ParkingLots.Where(l => l.Name == "Aria Mall").Select(l => l.Id).FirstOrDefaultAsync();

                if (vijeId != 0)
                    context.Reviews.Add(new Review
                    {
                        UserId = userId,
                        ParkingLotId = vijeId,
                        Rating = 5,
                        Comment = "Odlicna lokacija i uvijek ima mjesta.",
                        CreatedAt = seedDate
                    });

                if (ariaId != 0)
                    context.Reviews.Add(new Review
                    {
                        UserId = harisId,
                        ParkingLotId = ariaId,
                        Rating = 4,
                        Comment = "Sve ok, ali zna biti gu�va u �pici.",
                        CreatedAt = seedDate
                    });

                await context.SaveChangesAsync();
            }

            if (!await context.ParkingLotViewHistories.AnyAsync())
            {
                var userId = await context.MyAppUsers.Where(u => u.Username == "user").Select(u => u.Id).FirstAsync();
                var harisId = await context.MyAppUsers.Where(u => u.Username == "haris").Select(u => u.Id).FirstAsync();
                var vijeId = await context.ParkingLots.Where(l => l.Name == "Vijecnica").Select(l => l.Id).FirstOrDefaultAsync();
                var ariaId = await context.ParkingLots.Where(l => l.Name == "Aria Mall").Select(l => l.Id).FirstOrDefaultAsync();

                if (vijeId != 0)
                    context.ParkingLotViewHistories.Add(new ParkingLotViewHistory
                    {
                        UserId = userId,
                        ParkingLotId = vijeId,
                        ViewCount = 3,
                        LastViewedAt = seedDate,
                        CreatedAt = seedDate
                    });

                if (ariaId != 0)
                    context.ParkingLotViewHistories.Add(new ParkingLotViewHistory
                    {
                        UserId = harisId,
                        ParkingLotId = ariaId,
                        ViewCount = 2,
                        LastViewedAt = seedDate,
                        CreatedAt = seedDate
                    });

                await context.SaveChangesAsync();
            }
        }

        /// <summary>
        /// Parkinzi: Vijecnica (50), Bascarsija (20), Aria Mall (100).
        /// Gradska zona: samo Zona 1 (centar) i Zona 2 (periferija).
        /// </summary>
        private static async Task EnsureParkinziAndZonesAsync(ParkingDbContext context, DateTime seedDate)
        {
            var regularTypeId = await context.ParkingSpotTypes
                .Where(t => t.Name == "Regular")
                .Select(t => t.Id)
                .FirstOrDefaultAsync();
            if (regularTypeId == 0)
                return;

            await ConsolidateDuplicateParkingLotsAsync(context, seedDate);

            var parkinzi = new (string Name, string Key, string Search, int TargetCount, bool IsCentar)[]
            {
                ("Vijecnica", "vijecnica", "vijecnica", 50, true),
                ("Bascarsija", "bascarsija", "bascarsija", 20, true),
                ("Aria Mall", "aria mall", "aria mall", 100, false),
            };

            var locationAsZoneNames = new[] { "Vijecnica", "Bascarsija", "Ba?ar�ija", "Aria Mall", "Aria mall" };

            ParkingLot? centarLot = null;
            ParkingLot? periferijaLot = null;

            foreach (var def in parkinzi)
            {
                var lot = await FindParkingLotByKeyAsync(context, def.Key);

                if (lot == null)
                {
                    lot = new ParkingLot
                    {
                        Name = def.Name,
                        NumberOfSpots = 0,
                        Status = ParkingLotStatus.Active,
                        IsActive = true,
                        CreatedAt = seedDate
                    };
                    ApplyDefaultCoordinates(lot);
                    context.ParkingLots.Add(lot);
                    await context.SaveChangesAsync();
                }
                else
                {
                    lot.Name = def.Name;
                    lot.IsActive = true;
                }

                ApplyDefaultCoordinates(lot);

                if (def.IsCentar)
                    centarLot ??= lot;
                else
                    periferijaLot ??= lot;
            }

            centarLot ??= await context.ParkingLots.FirstAsync();
            periferijaLot ??= centarLot;

            var zona1 = await EnsureSingleCityZoneAsync(
                context,
                centarLot.Id,
                "Zona 1",
                "Centar grada (Vijecnica, Bascarsija).",
                seedDate);
            var zona2 = await EnsureSingleCityZoneAsync(
                context,
                periferijaLot.Id,
                "Zona 2",
                "Periferija (Aria Mall i �ire podrucje).",
                seedDate);

            await ConsolidateToTwoZonesAsync(
                context,
                zona1.Id,
                zona2.Id,
                centarLot.Id,
                periferijaLot.Id,
                seedDate);

            foreach (var def in parkinzi)
            {
                var zoneId = def.IsCentar ? zona1.Id : zona2.Id;

                var allForParkir = await context.ParkingSpots
                    .Where(s => s.DisplayNameSearch == def.Search)
                    .OrderBy(s => s.Id)
                    .ToListAsync();

                for (var i = 0; i < allForParkir.Count; i++)
                {
                    var spot = allForParkir[i];
                    spot.ZoneId = zoneId;
                    spot.DisplayName = def.Name;
                    spot.DisplayNameSearch = def.Search;
                    spot.IsActive = i < def.TargetCount;
                    spot.UpdatedAt = seedDate;
                }

                await context.SaveChangesAsync();

                var activeCount = allForParkir.Count(s => s.IsActive);

                var toAdd = def.TargetCount - activeCount;
                if (toAdd > 0)
                {
                    var maxNumber = await context.ParkingSpots.MaxAsync(s => (int?)s.ParkingNumber) ?? 0;
                    var newSpots = new List<ParkingSpot>();
                    for (var i = 1; i <= toAdd; i++)
                    {
                        newSpots.Add(new ParkingSpot
                        {
                            ParkingNumber = maxNumber + i,
                            ParkingSpotTypeId = regularTypeId,
                            ZoneId = zoneId,
                            DisplayName = def.Name,
                            DisplayNameSearch = def.Search,
                            IsActive = true,
                            CreatedAt = seedDate
                        });
                    }

                    context.ParkingSpots.AddRange(newSpots);
                    await context.SaveChangesAsync();
                }

                var lot = await FindParkingLotByKeyAsync(context, def.Key)
                    ?? throw new InvalidOperationException($"Parking lot '{def.Name}' missing after consolidation.");
                lot.NumberOfSpots = await context.ParkingSpots
                    .CountAsync(s => s.IsActive && s.DisplayNameSearch == def.Search);
                await context.SaveChangesAsync();
            }

            var locationZones = await context.ParkingZones
                .Where(z => locationAsZoneNames.Contains(z.Name))
                .ToListAsync();

            foreach (var zone in locationZones)
            {
                zone.IsActive = false;
                zone.UpdatedAt = seedDate;
                var spots = await context.ParkingSpots
                    .Where(s => s.ZoneId == zone.Id && s.IsActive)
                    .ToListAsync();
                foreach (var spot in spots)
                {
                    spot.IsActive = false;
                    spot.UpdatedAt = seedDate;
                }
            }

            var sarajevoLots = await context.ParkingLots
                .Where(l => l.Name == "Sarajevo")
                .ToListAsync();

            foreach (var lot in sarajevoLots)
            {
                lot.IsActive = false;
                lot.UpdatedAt = seedDate;
            }

            var legacyEnglishZones = await context.ParkingZones
                .Where(z => z.IsActive && (z.Name == "Zone 1" || z.Name == "Zone 2"))
                .ToListAsync();

            foreach (var zone in legacyEnglishZones)
            {
                zone.IsActive = false;
                zone.UpdatedAt = seedDate;
                var spots = await context.ParkingSpots
                    .Where(s => s.ZoneId == zone.Id && s.IsActive)
                    .ToListAsync();
                foreach (var spot in spots)
                {
                    spot.IsActive = false;
                    spot.UpdatedAt = seedDate;
                }
            }

            await context.SaveChangesAsync();

            var allLots = await context.ParkingLots.Where(l => l.IsActive).ToListAsync();
            var allSpots = await context.ParkingSpots
                .Where(s => s.IsActive)
                .Include(s => s.Zone)
                .ToListAsync();

            foreach (var lot in allLots)
            {
                lot.NumberOfSpots = allSpots.Count(s =>
                    s.DisplayNameSearch != null
                    && (
                        string.Equals(s.DisplayName, lot.Name, StringComparison.OrdinalIgnoreCase)
                        || (lot.Name.Contains("aria", StringComparison.OrdinalIgnoreCase)
                            && s.DisplayNameSearch == "aria mall")));
            }

            await CleanupLegacyZonesAsync(context);
            await DeactivateNonCanonicalParkingLotsAsync(context, seedDate);
            await DeleteInactiveParkingLotsAsync(context);
            await context.SaveChangesAsync();
        }

        /// <summary>
        /// Spaja duplikate (npr. Vijecnica id 2 i 1002) i ostavlja ta?no 3 aktivna parkinga.
        /// </summary>
        private static async Task ConsolidateDuplicateParkingLotsAsync(ParkingDbContext context, DateTime seedDate)
        {
            var canonicalKeys = new[] { "vijecnica", "bascarsija", "aria mall" };
            var allLots = await context.ParkingLots.ToListAsync();

            foreach (var key in canonicalKeys)
            {
                var matches = allLots
                    .Where(l => NormalizeParkingLotKey(l.Name) == key)
                    .OrderByDescending(l => l.IsActive)
                    .ThenByDescending(l => l.NumberOfSpots)
                    .ThenBy(l => l.Id)
                    .ToList();

                if (matches.Count == 0)
                    continue;

                var canonical = matches[0];
                canonical.Name = CanonicalParkingLotName(key);
                canonical.IsActive = true;
                canonical.UpdatedAt = seedDate;

                foreach (var duplicate in matches.Skip(1))
                {
                    await ReassignParkingLotReferencesAsync(context, duplicate.Id, canonical.Id);
                    duplicate.IsActive = false;
                    duplicate.NumberOfSpots = 0;
                    duplicate.UpdatedAt = seedDate;
                }
            }

            foreach (var lot in allLots.Where(l => NormalizeParkingLotKey(l.Name) == "sarajevo"))
            {
                lot.IsActive = false;
                lot.UpdatedAt = seedDate;
            }

            await context.SaveChangesAsync();
        }

        /// <summary>
        /// Fizi?ki bri�e neaktivne duplikate/legacy parkinge nakon spajanja referenci.
        /// </summary>
        private static async Task DeleteInactiveParkingLotsAsync(ParkingDbContext context)
        {
            var inactiveLots = await context.ParkingLots
                .Where(l => !l.IsActive)
                .ToListAsync();

            foreach (var lot in inactiveLots)
            {
                var zones = await context.ParkingZones
                    .Where(z => z.ParkingLotId == lot.Id)
                    .Include(z => z.ParkingSpots)
                    .ToListAsync();

                foreach (var zone in zones)
                {
                    var spotIds = zone.ParkingSpots.Select(s => s.Id).ToList();
                    if (spotIds.Count > 0
                        && await context.Reservations.AnyAsync(r => spotIds.Contains(r.ParkingSpotId)))
                    {
                        continue;
                    }

                    if (zone.ParkingSpots.Count > 0)
                        context.ParkingSpots.RemoveRange(zone.ParkingSpots);

                    context.ParkingZones.Remove(zone);
                }

                var blocked = await context.ParkingZones.AnyAsync(z => z.ParkingLotId == lot.Id)
                    || await context.FavoriteParkingLots.AnyAsync(f => f.ParkingLotId == lot.Id)
                    || await context.Reviews.AnyAsync(r => r.ParkingLotId == lot.Id)
                    || await context.ParkingLotViewHistories.AnyAsync(h => h.ParkingLotId == lot.Id);

                if (!blocked)
                    context.ParkingLots.Remove(lot);
            }

            await context.SaveChangesAsync();
        }

        private static async Task DeactivateNonCanonicalParkingLotsAsync(
            ParkingDbContext context,
            DateTime seedDate)
        {
            var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "vijecnica", "bascarsija", "aria mall", "sarajevo"
            };

            var lots = await context.ParkingLots.ToListAsync();
            foreach (var lot in lots)
            {
                var key = NormalizeParkingLotKey(lot.Name);
                if (key == null || !allowed.Contains(key))
                {
                    lot.IsActive = false;
                    lot.UpdatedAt = seedDate;
                }
            }
        }

        private static async Task ReassignParkingLotReferencesAsync(
            ParkingDbContext context,
            int fromLotId,
            int toLotId)
        {
            if (fromLotId == toLotId)
                return;

            var favorites = await context.FavoriteParkingLots
                .Where(f => f.ParkingLotId == fromLotId)
                .ToListAsync();
            foreach (var favorite in favorites)
            {
                var exists = await context.FavoriteParkingLots.AnyAsync(f =>
                    f.UserId == favorite.UserId && f.ParkingLotId == toLotId);
                if (exists)
                    context.FavoriteParkingLots.Remove(favorite);
                else
                    favorite.ParkingLotId = toLotId;
            }

            var reviews = await context.Reviews.Where(r => r.ParkingLotId == fromLotId).ToListAsync();
            foreach (var review in reviews)
            {
                var exists = await context.Reviews.AnyAsync(r =>
                    r.UserId == review.UserId && r.ParkingLotId == toLotId);
                if (exists)
                    context.Reviews.Remove(review);
                else
                    review.ParkingLotId = toLotId;
            }

            var histories = await context.ParkingLotViewHistories
                .Where(h => h.ParkingLotId == fromLotId)
                .ToListAsync();
            foreach (var history in histories)
            {
                var existing = await context.ParkingLotViewHistories.FirstOrDefaultAsync(h =>
                    h.UserId == history.UserId && h.ParkingLotId == toLotId);
                if (existing != null)
                {
                    existing.ViewCount += history.ViewCount;
                    if (history.LastViewedAt > existing.LastViewedAt)
                        existing.LastViewedAt = history.LastViewedAt;
                    context.ParkingLotViewHistories.Remove(history);
                }
                else
                {
                    history.ParkingLotId = toLotId;
                }
            }

            var zones = await context.ParkingZones.Where(z => z.ParkingLotId == fromLotId).ToListAsync();
            foreach (var zone in zones)
                zone.ParkingLotId = toLotId;
        }

        private static async Task<ParkingLot?> FindParkingLotByKeyAsync(ParkingDbContext context, string key)
        {
            var lots = await context.ParkingLots.ToListAsync();
            return lots
                .Where(l => NormalizeParkingLotKey(l.Name) == key)
                .OrderByDescending(l => l.IsActive)
                .ThenByDescending(l => l.NumberOfSpots)
                .ThenBy(l => l.Id)
                .FirstOrDefault();
        }

        private static string? NormalizeParkingLotKey(string? name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return null;

            var normalized = name.Trim().ToLowerInvariant();
            normalized = normalized
                .Replace("\u010D", "c")
                .Replace("\u0107", "c")
                .Replace("\u0161", "s")
                .Replace("\u017E", "z")
                .Replace("\u0111", "d");

            if (normalized.Contains("vijecnica"))
                return "vijecnica";
            if (normalized.Contains("bascarsij") || normalized.Contains("bascar"))
                return "bascarsija";
            if (normalized.Contains("aria"))
                return "aria mall";
            if (normalized == "sarajevo")
                return "sarajevo";

            return null;
        }

        private static string CanonicalParkingLotName(string key) => key switch
        {
            "vijecnica" => "Vijecnica",
            "bascarsija" => "Bascarsija",
            "aria mall" => "Aria Mall",
            _ => key
        };

        private static void ApplyDefaultCoordinates(ParkingLot lot)
        {
            if (lot.Latitude.HasValue && lot.Longitude.HasValue)
                return;

            var (lat, lng) = ParkingLotGeoHelper.GetCoordinates(lot);
            lot.Latitude = lat;
            lot.Longitude = lng;
        }

        /// <summary>
        /// Removes inactive legacy zones when they have no reservations (old Sarajevo / location-as-zone rows).
        /// </summary>
        private static async Task CleanupLegacyZonesAsync(ParkingDbContext context)
        {
            var inactiveLotIds = await context.ParkingLots
                .Where(l => !l.IsActive)
                .Select(l => l.Id)
                .ToListAsync();

            var legacyZones = await context.ParkingZones
                .Where(z => !z.IsActive || inactiveLotIds.Contains(z.ParkingLotId))
                .Include(z => z.ParkingSpots)
                .ToListAsync();

            foreach (var zone in legacyZones)
            {
                var spotIds = zone.ParkingSpots.Select(s => s.Id).ToList();
                if (spotIds.Count > 0
                    && await context.Reservations.AnyAsync(r => spotIds.Contains(r.ParkingSpotId)))
                {
                    continue;
                }

                if (zone.ParkingSpots.Count > 0)
                    context.ParkingSpots.RemoveRange(zone.ParkingSpots);

                context.ParkingZones.Remove(zone);
            }

            await context.SaveChangesAsync();
        }

        private static async Task<ParkingZone> EnsureSingleCityZoneAsync(
            ParkingDbContext context,
            int lotId,
            string name,
            string description,
            DateTime seedDate)
        {
            var zone = await context.ParkingZones
                .Where(z => z.ParkingLotId == lotId && z.Name == name)
                .OrderBy(z => z.Id)
                .FirstOrDefaultAsync();

            if (zone == null)
            {
                zone = new ParkingZone
                {
                    ParkingLotId = lotId,
                    Name = name,
                    Description = description,
                    IsActive = true,
                    CreatedAt = seedDate
                };
                context.ParkingZones.Add(zone);
            }
            else
            {
                zone.Name = name;
                zone.Description = description;
                zone.IsActive = true;
                zone.UpdatedAt = seedDate;
            }

            await context.SaveChangesAsync();
            return zone;
        }

        private static async Task ConsolidateToTwoZonesAsync(
            ParkingDbContext context,
            int zona1Id,
            int zona2Id,
            int centarLotId,
            int periferijaLotId,
            DateTime seedDate)
        {
            var keepIds = new[] { zona1Id, zona2Id };
            var extraZones = await context.ParkingZones
                .Where(z => z.IsActive && !keepIds.Contains(z.Id))
                .Include(z => z.ParkingSpots)
                .ToListAsync();

            foreach (var zone in extraZones)
            {
                foreach (var spot in zone.ParkingSpots.Where(s => s.IsActive))
                {
                    var isCentar = spot.DisplayName != null
                        && (spot.DisplayName.Contains("Vijecnica", StringComparison.OrdinalIgnoreCase)
                            || spot.DisplayName.Contains("Bascarsija", StringComparison.OrdinalIgnoreCase)
                            || spot.DisplayName.Contains("Bascar", StringComparison.OrdinalIgnoreCase)
                            || spot.DisplayNameSearch == "vijecnica"
                            || spot.DisplayNameSearch == "bascarsija");
                    spot.ZoneId = isCentar ? zona1Id : zona2Id;
                    spot.UpdatedAt = seedDate;
                }

                zone.IsActive = false;
                zone.UpdatedAt = seedDate;
            }

            await context.SaveChangesAsync();
        }

        private static async Task RenameLegacyZoneAsync(
            ParkingDbContext context,
            int lotId,
            string oldName,
            string newName,
            DateTime seedDate)
        {
            var legacy = await context.ParkingZones
                .FirstOrDefaultAsync(z => z.ParkingLotId == lotId && z.Name == oldName);

            if (legacy == null)
                return;

            var existing = await context.ParkingZones
                .FirstOrDefaultAsync(z => z.ParkingLotId == lotId && z.Name == newName);

            if (existing == null)
            {
                legacy.Name = newName;
                legacy.IsActive = true;
                legacy.UpdatedAt = seedDate;
                return;
            }

            var spots = await context.ParkingSpots.Where(s => s.ZoneId == legacy.Id).ToListAsync();
            foreach (var spot in spots)
            {
                spot.ZoneId = existing.Id;
                spot.UpdatedAt = seedDate;
            }

            legacy.IsActive = false;
            legacy.UpdatedAt = seedDate;
            await context.SaveChangesAsync();
        }

        private static async Task EnsureCountriesTableAsync(ParkingDbContext context)
        {
            await context.Database.ExecuteSqlRawAsync("""
                IF OBJECT_ID(N'[dbo].[Countries]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[Countries] (
                        [Id] int NOT NULL IDENTITY(1,1),
                        [Name] nvarchar(100) NOT NULL,
                        [IsActive] bit NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        [UpdatedAt] datetime2 NULL,
                        CONSTRAINT [PK_Countries] PRIMARY KEY ([Id])
                    );
                END
                """);
        }

        /// <summary>
        /// Clears lockouts and seeds dev passwords only when credentials are missing.
        /// Does not overwrite custom passwords on API restart.
        /// Default dev: admin/admin, user/user, haris/haris, desktop/test, mobile/test (RS2)
        /// </summary>
        public static async Task EnsureDevelopmentCredentialsAsync(ParkingDbContext context)
        {
            await EnsureUserPasswordAsync(context, "admin", "admin");
            await EnsureUserPasswordAsync(context, "user", "user");
            await EnsureUserPasswordAsync(context, "haris", "haris");
            await EnsureUserPasswordAsync(context, "desktop", "test");
            await EnsureUserPasswordAsync(context, "mobile", "test");
        }

        /// <summary>
        /// RS2 README nalozi: desktop/test (Admin), mobile/test (User).
        /// Kreira korisnike ako ne postoje; lozinka se usklađuje u EnsureDevelopmentCredentialsAsync.
        /// </summary>
        public static async Task EnsureRs2StandardUsersAsync(ParkingDbContext context)
        {
            var genderId = await context.Genders.Where(g => g.IsActive).Select(g => g.Id).FirstOrDefaultAsync();
            if (genderId == 0)
                genderId = await context.Genders.Select(g => g.Id).FirstOrDefaultAsync();

            var cityId = await context.Cities.Where(c => c.IsActive).Select(c => c.Id).FirstOrDefaultAsync();
            if (cityId == 0)
                cityId = await context.Cities.Select(c => c.Id).FirstOrDefaultAsync();

            var seedDate = DateTime.UtcNow;

            await EnsureRs2UserExistsAsync(
                context,
                username: "desktop",
                password: "test",
                firstName: "Desktop",
                lastName: "Admin",
                email: "desktop@eparking.local",
                isAdmin: true,
                isUser: false,
                genderId: genderId == 0 ? null : genderId,
                cityId: cityId == 0 ? null : cityId,
                seedDate: seedDate);

            await EnsureRs2UserExistsAsync(
                context,
                username: "mobile",
                password: "test",
                firstName: "Mobile",
                lastName: "User",
                email: "mobile@eparking.local",
                isAdmin: false,
                isUser: true,
                genderId: genderId == 0 ? null : genderId,
                cityId: cityId == 0 ? null : cityId,
                seedDate: seedDate);
        }

        private static async Task EnsureRs2UserExistsAsync(
            ParkingDbContext context,
            string username,
            string password,
            string firstName,
            string lastName,
            string email,
            bool isAdmin,
            bool isUser,
            int? genderId,
            int? cityId,
            DateTime seedDate)
        {
            if (await context.MyAppUsers.AnyAsync(u => u.Username == username))
                return;

            var (salt, hash) = PasswordHasher.CreateSeedHash(password, username);
            context.MyAppUsers.Add(new MyAppUser
            {
                Username = username,
                PasswordSalt = salt,
                PasswordHash = hash,
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                PhoneNumber = DefaultPhoneNumber,
                GenderId = genderId,
                CityId = cityId,
                IsAdmin = isAdmin,
                IsUser = isUser,
                IsActive = true,
                CreatedAt = seedDate,
            });
            await context.SaveChangesAsync();
        }

        private static async Task EnsureUserPasswordAsync(
            ParkingDbContext context,
            string username,
            string devPassword)
        {
            var user = await context.MyAppUsers.FirstOrDefaultAsync(u => u.Username == username);
            if (user == null)
                return;

            var hadLockout = user.FailedLoginAttempts != 0 || user.LockoutUntil != null;
            user.FailedLoginAttempts = 0;
            user.LockoutUntil = null;

            var hasCredentials = !string.IsNullOrEmpty(user.PasswordHash)
                && !string.IsNullOrEmpty(user.PasswordSalt);

            var passwordMatchesDev = hasCredentials
                && PasswordHasher.Verify(devPassword, user.PasswordSalt, user.PasswordHash);

            var needsPbkdf2Upgrade = hasCredentials
                && passwordMatchesDev
                && PasswordHasher.IsLegacyHash(user.PasswordHash);

            if (passwordMatchesDev && !needsPbkdf2Upgrade)
            {
                if (hadLockout)
                {
                    user.UpdatedAt = DateTime.UtcNow;
                    await context.SaveChangesAsync();
                }
                return;
            }

            var (salt, hash) = PasswordHasher.CreateSeedHash(devPassword, username);
            user.PasswordSalt = salt;
            user.PasswordHash = hash;
            user.UpdatedAt = DateTime.UtcNow;
            await context.SaveChangesAsync();
        }

        private static async Task SeedCountriesAsync(ParkingDbContext context, DateTime seedDate)
        {
            if (await context.Countries.AnyAsync())
                return;

            var countryNames = new[]
            {
                "Bosnia and Herzegovina",
                "France",
                "Germany",
                "Italy",
                "Norway",
                "Portugal",
                "Spain",
                "Turkey",
                "United Kingdom",
                "United States"
            };

            context.Countries.AddRange(countryNames.Select(name => new Country
            {
                Name = name,
                IsActive = true,
                CreatedAt = seedDate
            }));
            await context.SaveChangesAsync();
        }

        private static async Task EnsureBrandLogosAsync(ParkingDbContext context)
        {
            var logos = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["Mercedes-Benz"] = "1.png",
                ["BMW"] = "2.png",
                ["Volkswagen"] = "3.png"
            };

            var brands = await context.Brands
                .Where(b => b.Logo == null || b.Logo.Length == 0)
                .ToListAsync();

            foreach (var brand in brands)
            {
                if (logos.TryGetValue(brand.Name, out var fileName))
                    brand.Logo = ToSeedImageBytes(fileName);
            }

            if (brands.Count > 0)
                await context.SaveChangesAsync();
        }

        private static async Task EnsureCarPicturesAsync(ParkingDbContext context)
        {
            var pictures = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["E12-K-345"] = "golf7.jpg",
                ["021-A-356"] = "bmw-x6.jpg",
                ["E11-K-111"] = "passat8.jpg"
            };

            var cars = await context.Cars
                .Where(c => c.Picture == null || c.Picture.Length == 0)
                .ToListAsync();

            foreach (var car in cars)
            {
                if (pictures.TryGetValue(car.LicensePlate, out var fileName))
                    car.Picture = ToSeedImageBytes(fileName);
            }

            if (cars.Count > 0)
                await context.SaveChangesAsync();
        }

        private static byte[]? ToSeedImageBytes(string fileName)
        {
            var path = SeedAssetHelper.TryGetAssetFileName(WwwRootFolder, fileName);
            return path == null ? null : Encoding.UTF8.GetBytes(path);
        }

        private static byte[]? LoadSeedImageFile(string fileName)
        {
            var relative = SeedAssetHelper.TryGetAssetFileName(WwwRootFolder, fileName);
            if (relative == null)
                return null;

            var candidates = new[]
            {
                Path.Combine(Directory.GetCurrentDirectory(), WwwRootFolder, fileName),
                Path.Combine(AppContext.BaseDirectory, WwwRootFolder, fileName),
                Path.Combine(AppContext.BaseDirectory, "..", "..", "..", WwwRootFolder, fileName),
            };

            foreach (var path in candidates)
            {
                var full = Path.GetFullPath(path);
                if (File.Exists(full))
                    return File.ReadAllBytes(full);
            }

            return null;
        }

        private static async Task<IEnumerable<City>> GetSeedCitiesAsync(ParkingDbContext context, DateTime seedDate)
        {
            var countryIds = await context.Countries.ToDictionaryAsync(c => c.Name, c => c.Id);

            var entries = new (string City, string Country)[]
            {
                ("Sarajevo", "Bosnia and Herzegovina"), ("Mostar", "Bosnia and Herzegovina"),
                ("Banja Luka", "Bosnia and Herzegovina"), ("Jajce", "Bosnia and Herzegovina"),
                ("Trebinje", "Bosnia and Herzegovina"),
                ("Paris", "France"), ("Lyon", "France"), ("Nice", "France"), ("Cannes", "France"),
                ("Marseille", "France"),
                ("Berlin", "Germany"), ("Munich", "Germany"), ("Hamburg", "Germany"),
                ("Cologne", "Germany"), ("Frankfurt", "Germany"),
                ("Venice", "Italy"), ("Rome", "Italy"), ("Milan", "Italy"), ("Florence", "Italy"),
                ("Turin", "Italy"),
                ("Oslo", "Norway"), ("Bergen", "Norway"), ("Troms�", "Norway"),
                ("Stavanger", "Norway"), ("Trondheim", "Norway"),
                ("Lisbon", "Portugal"), ("Porto", "Portugal"), ("Faro", "Portugal"),
                ("Coimbra", "Portugal"), ("Braga", "Portugal"),
                ("Barcelona", "Spain"), ("Madrid", "Spain"), ("Seville", "Spain"),
                ("Valencia", "Spain"), ("Bilbao", "Spain"),
                ("Istanbul", "Turkey"), ("Ankara", "Turkey"), ("Izmir", "Turkey"),
                ("Antalya", "Turkey"), ("Bodrum", "Turkey"),
                ("London", "United Kingdom"), ("Edinburgh", "United Kingdom"),
                ("Manchester", "United Kingdom"), ("Bristol", "United Kingdom"),
                ("Brighton", "United Kingdom"),
                ("New Orleans", "United States"), ("Austin", "United States"),
                ("New York", "United States"), ("Los Angeles", "United States"), ("Miami", "United States")
            };

            return entries.Select(e => new City
            {
                Name = e.City,
                CountryId = countryIds[e.Country],
                IsActive = true,
                CreatedAt = seedDate
            });
        }

        private static async Task BackfillReservationStatusesAsync(ParkingDbContext context)
        {
            var now = DateTime.UtcNow;
            var reservations = await context.Reservations.ToListAsync();
            var changed = false;

            foreach (var reservation in reservations)
            {
                if (reservation.EndDate <= now &&
                    reservation.Status != (int)Model.ReservationStatus.Cancelled &&
                    reservation.Status != (int)Model.ReservationStatus.Completed)
                {
                    reservation.Status = (int)Model.ReservationStatus.Completed;
                    reservation.StatusChangedAt ??= reservation.UpdatedAt ?? reservation.CreatedAt;
                    reservation.StatusNote ??= "Backfill: automatski zavrseno (prosli termin).";
                    changed = true;
                }
            }

            if (changed)
                await context.SaveChangesAsync();
        }
    }
}
