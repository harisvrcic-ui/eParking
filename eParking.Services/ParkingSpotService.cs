using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class ParkingSpotService : IParkingSpotService
    {
        private readonly ParkingDbContext _context;
        private readonly IParkingLotService _parkingLotService;

        public ParkingSpotService(ParkingDbContext context, IParkingLotService parkingLotService)
        {
            _context = context;
            _parkingLotService = parkingLotService;
        }

        public async Task<PagedResponse<ParkingSpotResponse>> GetAllAsync(ParkingSpotSearch? search = null)
        {
            var query = BuildQuery();
            query = ApplyFilters(query, search);

            return await query
                .OrderBy(s => s.Id)
                .Select(s => new ParkingSpotResponse
                {
                    Id = s.Id,
                    ParkingNumber = s.ParkingNumber.ToString(),
                    ParkingSpotTypeId = s.ParkingSpotTypeId,
                    ParkingSpotTypeName = s.ParkingSpotType != null ? s.ParkingSpotType.Name : string.Empty,
                    ZoneId = s.ZoneId,
                    ZoneName = s.Zone != null ? s.Zone.Name : string.Empty,
                    ParkingLotId = s.Zone != null ? s.Zone.ParkingLotId : 0,
                    ParkingLotName = s.Zone != null && s.Zone.ParkingLot != null ? s.Zone.ParkingLot.Name : string.Empty,
                    IsActive = s.IsActive,
                    CreatedAt = s.CreatedAt,
                    UpdatedAt = s.UpdatedAt,
                    DisplayName = s.DisplayName
                })
                .ToPagedAsync(search);
        }

        public async Task<ParkingSpotResponse> GetByIdAsync(int id)
        {
            var spot = await BuildQuery().FirstOrDefaultAsync(s => s.Id == id);
            if (spot == null)
                throw new NotFoundException($"ParkingSpot with id {id} not found.");

            return MapToResponse(spot);
        }

        public async Task<ParkingSpotResponse> InsertAsync(ParkingSpotInsertRequest request)
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var zone = await EnsureZoneExistsAsync(request.ZoneId);
                await EnsureParkingSpotTypeExistsAsync(request.ParkingSpotTypeId);
                await EnsureParkingNumberUniqueAsync(request.ParkingNumber, request.ZoneId);

                var entity = new ParkingSpot
                {
                    ParkingNumber = ParseParkingNumber(request.ParkingNumber),
                    ParkingSpotTypeId = request.ParkingSpotTypeId,
                    ZoneId = request.ZoneId,
                    IsActive = request.IsActive,
                    CreatedAt = DateTime.UtcNow
                };

                SetDisplayNames(entity, zone.Name);

                _context.ParkingSpots.Add(entity);
                await _context.SaveChangesAsync();
                await _parkingLotService.RefreshSpotCountsAsync(persistChanges: false);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                entity = await BuildQuery().FirstAsync(s => s.Id == entity.Id);
                return MapToResponse(entity);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<ParkingSpotResponse> UpdateAsync(ParkingSpotUpdateRequest request)
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.ParkingSpots.FindAsync(request.Id);
                if (entity == null)
                    throw new NotFoundException($"ParkingSpot with id {request.Id} not found.");

                var zone = await EnsureZoneExistsAsync(request.ZoneId);
                await EnsureParkingSpotTypeExistsAsync(request.ParkingSpotTypeId);
                await EnsureParkingNumberUniqueAsync(request.ParkingNumber, request.ZoneId, request.Id);

                entity.ParkingNumber = ParseParkingNumber(request.ParkingNumber);
                entity.ParkingSpotTypeId = request.ParkingSpotTypeId;
                entity.ZoneId = request.ZoneId;
                entity.IsActive = request.IsActive;
                entity.UpdatedAt = DateTime.UtcNow;

                SetDisplayNames(entity, zone.Name);

                await _context.SaveChangesAsync();
                await _parkingLotService.RefreshSpotCountsAsync(persistChanges: false);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                entity = await BuildQuery().FirstAsync(s => s.Id == entity.Id);
                return MapToResponse(entity);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<PagedResponse<ParkingSpotResponse>> GetAvailableAsync(ParkingSpotAvailabilitySearch search)
        {
            var (startUtc, endUtc) = ReservationTimeHelper.NormalizeAndValidatePeriod(
                search.StartDate, search.EndDate);

            var blockingStatuses = new[] { (int)ReservationStatus.Pending, (int)ReservationStatus.Confirmed };

            var reservedSpotIds = await _context.Reservations
                .Where(r =>
                    blockingStatuses.Contains(r.Status) &&
                    r.StartDate < endUtc &&
                    r.EndDate > startUtc)
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToListAsync();

            var query = BuildQuery()
                .Where(s => s.IsActive && !reservedSpotIds.Contains(s.Id));

            if (search.ParkingLotId.HasValue)
                query = query.Where(s => s.Zone.ParkingLotId == search.ParkingLotId.Value);

            if (search.ZoneId.HasValue)
                query = query.Where(s => s.ZoneId == search.ZoneId.Value);

            return await query
                .OrderBy(s => s.ParkingNumber)
                .Select(s => new ParkingSpotResponse
                {
                    Id = s.Id,
                    ParkingNumber = s.ParkingNumber.ToString(),
                    ParkingSpotTypeId = s.ParkingSpotTypeId,
                    ParkingSpotTypeName = s.ParkingSpotType != null ? s.ParkingSpotType.Name : string.Empty,
                    ZoneId = s.ZoneId,
                    ZoneName = s.Zone != null ? s.Zone.Name : string.Empty,
                    ParkingLotId = s.Zone != null ? s.Zone.ParkingLotId : 0,
                    ParkingLotName = s.Zone != null && s.Zone.ParkingLot != null ? s.Zone.ParkingLot.Name : string.Empty,
                    IsActive = s.IsActive,
                    CreatedAt = s.CreatedAt,
                    UpdatedAt = s.UpdatedAt,
                    DisplayName = s.DisplayName
                })
                .ToPagedAsync(search);
        }

        public async Task DeleteAsync(int id)
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = await _context.ParkingSpots
                    .Include(s => s.Reservations)
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (entity == null)
                    throw new NotFoundException($"ParkingSpot with id {id} not found.");

                if (entity.Reservations.Any())
                    throw new BusinessException("Cannot delete a spot that has reservations.");

                _context.ParkingSpots.Remove(entity);
                await _context.SaveChangesAsync();
                await _parkingLotService.RefreshSpotCountsAsync(persistChanges: false);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        private IQueryable<ParkingSpot> BuildQuery()
        {
            return _context.ParkingSpots
                .AsNoTracking()
                .Include(s => s.ParkingSpotType)
                .Include(s => s.Zone)
                    .ThenInclude(z => z.ParkingLot);
        }

        private static IQueryable<ParkingSpot> ApplyFilters(IQueryable<ParkingSpot> query, ParkingSpotSearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.ParkingNumber)
                && int.TryParse(search.ParkingNumber.Trim(), out var parkingNumber))
                query = query.Where(s => s.ParkingNumber == parkingNumber);

            if (search.ZoneId.HasValue)
                query = query.Where(s => s.ZoneId == search.ZoneId.Value);

            if (search.ParkingLotId.HasValue)
                query = query.Where(s => s.Zone.ParkingLotId == search.ParkingLotId.Value);

            if (search.ParkingSpotTypeId.HasValue)
                query = query.Where(s => s.ParkingSpotTypeId == search.ParkingSpotTypeId.Value);

            if (search.IsActive.HasValue)
                query = query.Where(s => s.IsActive == search.IsActive.Value);

            return query;
        }

        private async Task<ParkingZone> EnsureZoneExistsAsync(int zoneId)
        {
            var zone = await _context.ParkingZones.FirstOrDefaultAsync(z => z.Id == zoneId);
            if (zone == null)
                throw new NotFoundException($"ParkingZone with id {zoneId} not found.");

            return zone;
        }

        private async Task EnsureParkingSpotTypeExistsAsync(int parkingSpotTypeId)
        {
            if (!await _context.ParkingSpotTypes.AnyAsync(t => t.Id == parkingSpotTypeId))
                throw new NotFoundException($"ParkingSpotType with id {parkingSpotTypeId} not found.");
        }

        private async Task EnsureParkingNumberUniqueAsync(string parkingNumber, int zoneId, int? excludeId = null)
        {
            var normalized = ParseParkingNumber(parkingNumber);
            var exists = await _context.ParkingSpots.AnyAsync(s =>
                s.ZoneId == zoneId &&
                s.ParkingNumber == normalized &&
                (!excludeId.HasValue || s.Id != excludeId.Value));

            if (exists)
                throw new BusinessException($"Parking number '{normalized}' already exists in this zone.");
        }

        private static int ParseParkingNumber(string parkingNumber)
        {
            if (!int.TryParse(parkingNumber.Trim(), out var number))
                throw new BusinessException("Parking number must be a valid integer.");

            return number;
        }

        private static void SetDisplayNames(ParkingSpot spot, string zoneName)
        {
            spot.DisplayName = $"{spot.ParkingNumber} ({zoneName})";
            spot.DisplayNameSearch = spot.DisplayName.ToLowerInvariant();
        }

        private static ParkingSpotResponse MapToResponse(ParkingSpot spot)
        {
            return new ParkingSpotResponse
            {
                Id = spot.Id,
                ParkingNumber = spot.ParkingNumber.ToString(),
                ParkingSpotTypeId = spot.ParkingSpotTypeId,
                ParkingSpotTypeName = spot.ParkingSpotType?.Name ?? string.Empty,
                ZoneId = spot.ZoneId,
                ZoneName = spot.Zone?.Name ?? string.Empty,
                ParkingLotId = spot.Zone?.ParkingLotId ?? 0,
                ParkingLotName = spot.Zone?.ParkingLot?.Name ?? string.Empty,
                IsActive = spot.IsActive,
                CreatedAt = spot.CreatedAt,
                UpdatedAt = spot.UpdatedAt,
                DisplayName = spot.DisplayName
            };
        }
    }
}
