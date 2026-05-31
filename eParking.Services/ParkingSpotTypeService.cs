using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IParkingSpotTypeService : IBaseCRUDService<ParkingSpotTypeResponse, ParkingSpotTypeSearch, ParkingSpotTypeInsertRequest, ParkingSpotTypeUpdateRequest> { }

    public class ParkingSpotTypeService : IParkingSpotTypeService
    {
        private readonly ParkingDbContext _context;

        public ParkingSpotTypeService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<ParkingSpotTypeResponse>> GetAllAsync(ParkingSpotTypeSearch? search = null)
        {
            var query = _context.ParkingSpotTypes.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(t => t.Name.Contains(search.Name));
            return await query.OrderBy(t => t.Id).Select(t => Map(t)).ToPagedAsync(search);
        }

        public async Task<ParkingSpotTypeResponse> GetByIdAsync(int id)
        {
            var entity = await _context.ParkingSpotTypes.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException($"ParkingSpotType with id {id} not found.");
            return Map(entity);
        }

        public async Task<ParkingSpotTypeResponse> InsertAsync(ParkingSpotTypeInsertRequest request)
        {
            var entity = new ParkingSpotType
            {
                Name = request.Name.Trim(),
                Description = request.Description.Trim(),
                PriceMultiplier = request.PriceMultiplier,
                CreatedAt = DateTime.UtcNow
            };
            _context.ParkingSpotTypes.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<ParkingSpotTypeResponse> UpdateAsync(ParkingSpotTypeUpdateRequest request)
        {
            var entity = await _context.ParkingSpotTypes.FindAsync(request.Id)
                ?? throw new NotFoundException($"ParkingSpotType with id {request.Id} not found.");
            entity.Name = request.Name.Trim();
            entity.Description = request.Description.Trim();
            entity.PriceMultiplier = request.PriceMultiplier;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.ParkingSpotTypes.Include(t => t.ParkingSpots).FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException($"ParkingSpotType with id {id} not found.");
            if (entity.ParkingSpots.Any())
                throw new BusinessException("Cannot delete a spot type that is used by parking spots.");
            _context.ParkingSpotTypes.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static ParkingSpotTypeResponse Map(ParkingSpotType t) => new()
        {
            Id = t.Id, Name = t.Name, Description = t.Description, PriceMultiplier = t.PriceMultiplier,
            CreatedAt = t.CreatedAt, UpdatedAt = t.UpdatedAt
        };
    }
}
