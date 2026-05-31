using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IBrandService : IBaseCRUDService<BrandResponse, BrandSearch, BrandInsertRequest, BrandUpdateRequest> { }

    public class BrandService : IBrandService
    {
        private readonly ParkingDbContext _context;

        public BrandService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<BrandResponse>> GetAllAsync(BrandSearch? search = null)
        {
            var query = _context.Brands.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(b => b.Name.Contains(search.Name));
            if (search?.IsActive.HasValue == true)
                query = query.Where(b => b.IsActive == search.IsActive.Value);

            return await query
                .OrderBy(b => b.Id)
                .Select(b => new BrandResponse
                {
                    Id = b.Id,
                    Name = b.Name,
                    Logo = null,
                    IsActive = b.IsActive,
                    CreatedAt = b.CreatedAt,
                    UpdatedAt = b.UpdatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<BrandResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Brands.AsNoTracking().FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new NotFoundException($"Brand with id {id} not found.");
            return Map(entity);
        }

        public async Task<BrandResponse> InsertAsync(BrandInsertRequest request)
        {
            var entity = new Brand
            {
                Name = request.Name.Trim(),
                Logo = BinaryFieldHelper.FromApiImageString(request.Logo),
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };
            _context.Brands.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<BrandResponse> UpdateAsync(BrandUpdateRequest request)
        {
            var entity = await _context.Brands.FindAsync(request.Id)
                ?? throw new NotFoundException($"Brand with id {request.Id} not found.");
            entity.Name = request.Name.Trim();
            entity.Logo = BinaryFieldHelper.FromApiImageString(request.Logo);
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Brands.Include(b => b.Cars).FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new NotFoundException($"Brand with id {id} not found.");
            if (entity.Cars.Any())
                throw new BusinessException("Cannot delete a brand that is used by cars.");
            _context.Brands.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static BrandResponse Map(Brand b) => new()
        {
            Id = b.Id, Name = b.Name, Logo = BinaryFieldHelper.ToApiString(b.Logo), IsActive = b.IsActive,
            CreatedAt = b.CreatedAt, UpdatedAt = b.UpdatedAt
        };
    }
}
