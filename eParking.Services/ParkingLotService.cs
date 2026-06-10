using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class ParkingLotService : IParkingLotService
    {
        private readonly ParkingDbContext _context;
        private readonly MapsterMapper.IMapper _mapper;

        public ParkingLotService(ParkingDbContext context, MapsterMapper.IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PagedResponse<ParkingLotResponse>> GetAllAsync(ParkingLotSearch? search = null)
        {
            var query = _context.ParkingLots
                .AsNoTracking()
                .Include(l => l.Zones)
                .AsQueryable();

            query = ApplyFilters(query, search);

            return await query
                .OrderBy(l => l.Id)
                .Select(l => new ParkingLotResponse
                {
                    Id = l.Id,
                    Name = l.Name,
                    NumberOfSpots = l.NumberOfSpots,
                    Status = l.Status.ToString(),
                    IsActive = l.IsActive,
                    Latitude = l.Latitude,
                    Longitude = l.Longitude,
                    CreatedAt = l.CreatedAt,
                    UpdatedAt = l.UpdatedAt,
                    ZoneCount = l.Zones.Count
                })
                .ToPagedAsync(search);
        }

        public async Task<ParkingLotResponse> GetByIdAsync(int id)
        {
            var lot = await _context.ParkingLots
                .AsNoTracking()
                .Include(l => l.Zones)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (lot == null)
                throw new NotFoundException($"ParkingLot with id {id} not found.");

            return MapToResponse(lot);
        }

        public async Task<ParkingLotResponse> InsertAsync(ParkingLotInsertRequest request)
        {
            var entity = new ParkingLot
            {
                Name = request.Name,
                Status = Enum.IsDefined(typeof(ParkingLotStatus), request.Status)
                    ? (ParkingLotStatus)request.Status
                    : ParkingLotStatus.Active,
                IsActive = request.IsActive,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                NumberOfSpots = 0,
                CreatedAt = DateTime.UtcNow
            };

            _context.ParkingLots.Add(entity);
            await _context.SaveChangesAsync();

            return MapToResponse(entity);
        }

        public async Task<ParkingLotResponse> UpdateAsync(ParkingLotUpdateRequest request)
        {
            var entity = await _context.ParkingLots.FindAsync(request.Id);
            if (entity == null)
                throw new NotFoundException($"ParkingLot with id {request.Id} not found.");

            entity.Name = request.Name;
            entity.Status = Enum.IsDefined(typeof(ParkingLotStatus), request.Status)
                ? (ParkingLotStatus)request.Status
                : entity.Status;
            entity.IsActive = request.IsActive;
            entity.Latitude = request.Latitude;
            entity.Longitude = request.Longitude;
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await RefreshSpotCountsAsync();

            entity = await _context.ParkingLots
                .AsNoTracking()
                .Include(l => l.Zones)
                .FirstAsync(l => l.Id == entity.Id);

            return MapToResponse(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.ParkingLots
                .Include(l => l.Zones)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (entity == null)
                throw new NotFoundException($"ParkingLot with id {id} not found.");

            if (entity.Zones.Any())
                throw new BusinessException("Cannot delete a parking lot that has zones. Remove zones first.");

            _context.ParkingLots.Remove(entity);
            await _context.SaveChangesAsync();
        }

        public async Task RefreshSpotCountsAsync(bool persistChanges = true)
        {
            var lots = await _context.ParkingLots.ToListAsync();
            var spots = await _context.ParkingSpots
                .Where(s => s.IsActive)
                .Include(s => s.Zone)
                .ToListAsync();

            foreach (var lot in lots)
            {
                lot.NumberOfSpots = spots.Count(s => SpotBelongsToLot(s, lot.Id));
            }

            if (persistChanges)
                await _context.SaveChangesAsync();
        }

        private static bool SpotBelongsToLot(ParkingSpot spot, int lotId)
            => spot.Zone != null && spot.Zone.ParkingLotId == lotId;

        private static IQueryable<ParkingSpot> FilterSpotsForLot(IQueryable<ParkingSpot> query, int lotId)
            => query.Where(s => s.IsActive && s.Zone.ParkingLotId == lotId);

        private static IQueryable<ParkingSpot> FilterSpotsForLots(
            IQueryable<ParkingSpot> query,
            IReadOnlyCollection<int> lotIds)
        {
            if (lotIds.Count == 0)
                return query.Where(_ => false);

            return query.Where(s => s.IsActive && lotIds.Contains(s.Zone.ParkingLotId));
        }


        public async Task<PagedResponse<ParkingLotOverviewResponse>> GetOverviewAsync(ParkingLotSearch? search = null)
        {
            var reservedSpotIds = (await GetReservedSpotIdsNowAsync()).ToHashSet();

            var lotsQuery = _context.ParkingLots
                .AsNoTracking()
                .Include(l => l.Zones)
                .AsQueryable();

            lotsQuery = ApplyFilters(lotsQuery, search);
            if (search?.IsActive != false)
                lotsQuery = lotsQuery.Where(l => l.IsActive);

            var lots = await lotsQuery.OrderBy(l => l.Name).ToListAsync();

            var lotIds = lots.Select(l => l.Id).ToList();
            var spotRows = lots.Count == 0
                ? []
                : await FilterSpotsForLots(_context.ParkingSpots.AsNoTracking(), lotIds)
                    .Select(s => new { s.Id, LotId = s.Zone.ParkingLotId })
                    .ToListAsync();

            var overview = lots.Select(lot =>
            {
                var lotSpotIds = spotRows
                    .Where(r => r.LotId == lot.Id)
                    .Select(r => r.Id)
                    .ToList();
                var available = lotSpotIds.Count(id => !reservedSpotIds.Contains(id));
                var (lat, lng) = ParkingLotGeoHelper.GetCoordinates(lot);

                return new ParkingLotOverviewResponse
                {
                    Id = lot.Id,
                    Name = lot.Name,
                    TotalSpots = lotSpotIds.Count,
                    AvailableSpots = available,
                    ZoneCount = lot.Zones?.Count(z => z.IsActive) ?? 0,
                    Status = lot.Status.ToString(),
                    IsActive = lot.IsActive,
                    Latitude = lat,
                    Longitude = lng
                };
            }).ToList();

            return PaginationHelper.FromList(overview, search);
        }

        public async Task<ParkingLotDetailResponse> GetDetailAsync(int id)
        {
            var lot = await _context.ParkingLots
                .AsNoTracking()
                .Include(l => l.Zones)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (lot == null)
                throw new NotFoundException($"ParkingLot with id {id} not found.");

            var reservedSpotIds = (await GetReservedSpotIdsNowAsync()).ToHashSet();

            var spots = await FilterSpotsForLot(_context.ParkingSpots.AsNoTracking(), lot.Id)
                .Include(s => s.Zone)
                .Include(s => s.ParkingSpotType)
                .OrderBy(s => s.Zone.Name)
                .ThenBy(s => s.ParkingNumber)
                .ToListAsync();

            var (lat, lng) = ParkingLotGeoHelper.GetCoordinates(lot);
            var available = spots.Count(s => !reservedSpotIds.Contains(s.Id));

            var zones = spots
                .GroupBy(s => s.ZoneId)
                .OrderBy(g => g.First().Zone?.Name)
                .Select(g =>
                {
                    var zone = g.First().Zone!;
                    return new ParkingZoneDetailResponse
                    {
                        Id = zone.Id,
                        Name = zone.Name,
                        Description = zone.Description,
                        Spots = g
                            .Select(s => new ParkingSpotDetailResponse
                            {
                                Id = s.Id,
                                ParkingNumber = s.ParkingNumber.ToString(),
                                DisplayName = s.DisplayName,
                                ZoneName = zone.Name,
                                SpotTypeName = s.ParkingSpotType?.Name ?? string.Empty,
                                IsAvailableNow = !reservedSpotIds.Contains(s.Id)
                            })
                            .ToList()
                    };
                })
                .ToList();

            return new ParkingLotDetailResponse
            {
                Id = lot.Id,
                Name = lot.Name,
                TotalSpots = spots.Count,
                AvailableSpots = available,
                Status = lot.Status.ToString(),
                Latitude = lat,
                Longitude = lng,
                Zones = zones
            };
        }

        /// <summary>
        /// Spot IDs with a reservation active at this moment (not the whole calendar day).
        /// </summary>
        private async Task<List<int>> GetReservedSpotIdsNowAsync()
        {
            var now = ReservationTimeHelper.UtcNow;
            var blockingStatuses = new[] { (int)Model.ReservationStatus.Pending, (int)Model.ReservationStatus.Confirmed };

            return await _context.Reservations
                .AsNoTracking()
                .Where(r => blockingStatuses.Contains(r.Status)
                    && r.StartDate <= now
                    && r.EndDate > now)
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToListAsync();
        }

        private static IQueryable<ParkingLot> ApplyFilters(IQueryable<ParkingLot> query, ParkingLotSearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(l => l.Name.Contains(search.Name));
            }

            if (search.Status.HasValue && Enum.IsDefined(typeof(ParkingLotStatus), search.Status.Value))
            {
                var status = (ParkingLotStatus)search.Status.Value;
                query = query.Where(l => l.Status == status);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(l => l.IsActive == search.IsActive.Value);
            }

            return query;
        }

        private ParkingLotResponse MapToResponse(ParkingLot lot)
        {
            return new ParkingLotResponse
            {
                Id = lot.Id,
                Name = lot.Name,
                NumberOfSpots = lot.NumberOfSpots,
                Status = lot.Status.ToString(),
                IsActive = lot.IsActive,
                Latitude = lot.Latitude,
                Longitude = lot.Longitude,
                CreatedAt = lot.CreatedAt,
                UpdatedAt = lot.UpdatedAt,
                ZoneCount = lot.Zones?.Count ?? 0
            };
        }
    }
}
