using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IColorService : IBaseCRUDService<ColorResponse, ColorSearch, ColorInsertRequest, ColorUpdateRequest> { }

    public class ColorService : IColorService
    {
        private readonly ParkingDbContext _context;

        public ColorService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<ColorResponse>> GetAllAsync(ColorSearch? search = null)
        {
            var query = _context.Colors.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(c => c.Name.Contains(search.Name));
            return await query.OrderBy(c => c.Id).Select(c => Map(c)).ToPagedAsync(search);
        }

        public async Task<ColorResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Colors.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"Color with id {id} not found.");
            return Map(entity);
        }

        public async Task<ColorResponse> InsertAsync(ColorInsertRequest request)
        {
            var entity = new Color { Name = request.Name.Trim(), HexCode = request.HexCode, CreatedAt = DateTime.UtcNow };
            _context.Colors.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<ColorResponse> UpdateAsync(ColorUpdateRequest request)
        {
            var entity = await _context.Colors.FindAsync(request.Id)
                ?? throw new NotFoundException($"Color with id {request.Id} not found.");
            entity.Name = request.Name.Trim();
            entity.HexCode = request.HexCode;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Colors.Include(c => c.Cars).FirstOrDefaultAsync(c => c.Id == id)
                ?? throw new NotFoundException($"Color with id {id} not found.");
            if (entity.Cars.Any())
                throw new BusinessException("Cannot delete a color that is used by cars.");
            _context.Colors.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static ColorResponse Map(Color c) => new()
        {
            Id = c.Id, Name = c.Name, HexCode = c.HexCode, CreatedAt = c.CreatedAt, UpdatedAt = c.UpdatedAt
        };
    }
}
