using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class ParkingZoneService : IParkingZoneService
    {
        private readonly ParkingDbContext _context;

        public ParkingZoneService(ParkingDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<ParkingZoneResponse>> GetAllAsync(ParkingZoneSearch? search = null)
        {
            var query = BuildQuery();
            query = ApplyFilters(query, search);

            return await query
                .OrderBy(z => z.Id)
                .Select(z => new ParkingZoneResponse
                {
                    Id = z.Id,
                    ParkingLotId = z.ParkingLotId,
                    ParkingLotName = z.ParkingLot != null ? z.ParkingLot.Name : string.Empty,
                    Name = z.Name,
                    Description = z.Description,
                    IsActive = z.IsActive,
                    CreatedAt = z.CreatedAt,
                    UpdatedAt = z.UpdatedAt,
                    SpotCount = z.ParkingSpots.Count(s => s.IsActive)
                })
                .ToPagedAsync(search);
        }

        public async Task<ParkingZoneResponse> GetByIdAsync(int id)
        {
            var zone = await BuildQuery().FirstOrDefaultAsync(z => z.Id == id);
            if (zone == null)
                throw new NotFoundException($"ParkingZone with id {id} not found.");

            return MapToResponse(zone);
        }

        public async Task<ParkingZoneResponse> InsertAsync(ParkingZoneInsertRequest request)
        {
            await EnsureParkingLotExistsAsync(request.ParkingLotId);

            var entity = new ParkingZone
            {
                ParkingLotId = request.ParkingLotId,
                Name = request.Name,
                Description = request.Description?.Trim(),
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.ParkingZones.Add(entity);
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(z => z.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task<ParkingZoneResponse> UpdateAsync(ParkingZoneUpdateRequest request)
        {
            var entity = await _context.ParkingZones.FindAsync(request.Id);
            if (entity == null)
                throw new NotFoundException($"ParkingZone with id {request.Id} not found.");

            await EnsureParkingLotExistsAsync(request.ParkingLotId);

            entity.ParkingLotId = request.ParkingLotId;
            entity.Name = request.Name;
            entity.Description = request.Description?.Trim();
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(z => z.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.ParkingZones
                .Include(z => z.ParkingSpots)
                .FirstOrDefaultAsync(z => z.Id == id);

            if (entity == null)
                throw new NotFoundException($"ParkingZone with id {id} not found.");

            if (entity.ParkingSpots.Any())
                throw new BusinessException("Cannot delete a zone that has parking spots. Remove spots first.");

            _context.ParkingZones.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private IQueryable<ParkingZone> BuildQuery()
        {
            return _context.ParkingZones
                .AsNoTracking()
                .Include(z => z.ParkingLot)
                .Include(z => z.ParkingSpots);
        }

        private static IQueryable<ParkingZone> ApplyFilters(IQueryable<ParkingZone> query, ParkingZoneSearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(z => z.Name.Contains(search.Name));

            if (search.ParkingLotId.HasValue)
                query = query.Where(z => z.ParkingLotId == search.ParkingLotId.Value);

            if (search.IsActive.HasValue)
                query = query.Where(z => z.IsActive == search.IsActive.Value);

            return query;
        }

        private async Task EnsureParkingLotExistsAsync(int parkingLotId)
        {
            if (!await _context.ParkingLots.AnyAsync(l => l.Id == parkingLotId))
                throw new NotFoundException($"ParkingLot with id {parkingLotId} not found.");
        }

        private static ParkingZoneResponse MapToResponse(ParkingZone zone)
        {
            return new ParkingZoneResponse
            {
                Id = zone.Id,
                ParkingLotId = zone.ParkingLotId,
                ParkingLotName = zone.ParkingLot?.Name ?? string.Empty,
                Name = zone.Name,
                Description = zone.Description,
                IsActive = zone.IsActive,
                CreatedAt = zone.CreatedAt,
                UpdatedAt = zone.UpdatedAt,
                SpotCount = zone.ParkingSpots?.Count(s => s.IsActive) ?? 0
            };
        }
    }
}
