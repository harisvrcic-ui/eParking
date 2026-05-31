using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface ICityService : IBaseCRUDService<CityResponse, CitySearch, CityInsertRequest, CityUpdateRequest> { }

    public class CityService : ICityService
    {
        private readonly ParkingDbContext _context;

        public CityService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<CityResponse>> GetAllAsync(CitySearch? search = null)
        {
            var query = _context.Cities.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(c => c.Name.Contains(search.Name));
            if (search?.IsActive.HasValue == true)
                query = query.Where(c => c.IsActive == search.IsActive.Value);
            return await query.OrderBy(c => c.Id)
                .Select(c => new CityResponse
                {
                    Id = c.Id,
                    Name = c.Name,
                    CountryId = c.CountryId,
                    CountryName = c.Country != null ? c.Country.Name : null,
                    IsActive = c.IsActive,
                    CreatedAt = c.CreatedAt,
                    UpdatedAt = c.UpdatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<CityResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Cities.AsNoTracking()
                .Include(c => c.Country)
                .FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"City with id {id} not found.");
            return Map(entity);
        }

        public async Task<CityResponse> InsertAsync(CityInsertRequest request)
        {
            var entity = new City
            {
                Name = request.Name.Trim(),
                CountryId = request.CountryId,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };
            _context.Cities.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<CityResponse> UpdateAsync(CityUpdateRequest request)
        {
            var entity = await _context.Cities.FindAsync(request.Id)
                ?? throw new NotFoundException($"City with id {request.Id} not found.");
            entity.Name = request.Name.Trim();
            entity.CountryId = request.CountryId;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Cities.Include(c => c.Users).FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"City with id {id} not found.");
            if (entity.Users.Any())
                throw new BusinessException("Cannot delete a city that is used by users.");
            _context.Cities.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static CityResponse Map(City c) => new()
        {
            Id = c.Id, Name = c.Name, CountryId = c.CountryId, CountryName = c.Country?.Name,
            IsActive = c.IsActive,
            CreatedAt = c.CreatedAt, UpdatedAt = c.UpdatedAt
        };
    }
}
