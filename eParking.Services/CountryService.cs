using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface ICountryService : IBaseCRUDService<CountryResponse, CountrySearch, CountryInsertRequest, CountryUpdateRequest> { }

    public class CountryService : ICountryService
    {
        private readonly ParkingDbContext _context;

        public CountryService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<CountryResponse>> GetAllAsync(CountrySearch? search = null)
        {
            var query = _context.Countries.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(c => c.Name.Contains(search.Name));
            if (search?.IsActive.HasValue == true)
                query = query.Where(c => c.IsActive == search.IsActive.Value);

            return await query.OrderBy(c => c.Id).Select(c => Map(c)).ToPagedAsync(search);
        }

        public async Task<CountryResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Countries.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"Country with id {id} not found.");
            return Map(entity);
        }

        public async Task<CountryResponse> InsertAsync(CountryInsertRequest request)
        {
            var entity = new Country
            {
                Name = request.Name.Trim(),
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };
            _context.Countries.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<CountryResponse> UpdateAsync(CountryUpdateRequest request)
        {
            var entity = await _context.Countries.FindAsync(request.Id)
                ?? throw new NotFoundException($"Country with id {request.Id} not found.");
            entity.Name = request.Name.Trim();
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Countries.Include(c => c.Cities).FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"Country with id {id} not found.");
            if (entity.Cities.Any())
                throw new BusinessException("Cannot delete a country that is used by cities.");
            _context.Countries.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static CountryResponse Map(Country c) => new()
        {
            Id = c.Id,
            Name = c.Name,
            IsActive = c.IsActive,
            CreatedAt = c.CreatedAt,
            UpdatedAt = c.UpdatedAt
        };
    }
}
