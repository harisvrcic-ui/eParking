using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IFavoriteParkingLotService
        : IBaseCRUDService<FavoriteParkingLotResponse, FavoriteParkingLotSearch, FavoriteParkingLotInsertRequest, FavoriteParkingLotUpdateRequest>
    {
    }

    public class FavoriteParkingLotService : IFavoriteParkingLotService
    {
        private readonly ParkingDbContext _context;

        public FavoriteParkingLotService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<FavoriteParkingLotResponse>> GetAllAsync(FavoriteParkingLotSearch? search = null)
        {
            var query = _context.FavoriteParkingLots
                .AsNoTracking()
                .Include(x => x.ParkingLot)
                .AsQueryable();

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId.Value);
            if (search?.ParkingLotId.HasValue == true)
                query = query.Where(x => x.ParkingLotId == search.ParkingLotId.Value);

            return await query
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new FavoriteParkingLotResponse
                {
                    Id = x.Id,
                    UserId = x.UserId,
                    ParkingLotId = x.ParkingLotId,
                    ParkingLotName = x.ParkingLot != null ? x.ParkingLot.Name : string.Empty,
                    CreatedAt = x.CreatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<FavoriteParkingLotResponse> GetByIdAsync(int id)
        {
            var entity = await _context.FavoriteParkingLots
                .AsNoTracking()
                .Include(x => x.ParkingLot)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException($"FavoriteParkingLot with id {id} not found.");

            return new FavoriteParkingLotResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                ParkingLotId = entity.ParkingLotId,
                ParkingLotName = entity.ParkingLot?.Name ?? string.Empty,
                CreatedAt = entity.CreatedAt
            };
        }

        public async Task<FavoriteParkingLotResponse> InsertAsync(FavoriteParkingLotInsertRequest request)
        {
            // Ensure user and parking lot exist (FK will enforce, but message is clearer).
            var userExists = await _context.MyAppUsers.AnyAsync(u => u.Id == request.UserId);
            if (!userExists) throw new NotFoundException($"User with id {request.UserId} not found.");

            var lotExists = await _context.ParkingLots.AnyAsync(l => l.Id == request.ParkingLotId);
            if (!lotExists) throw new NotFoundException($"ParkingLot with id {request.ParkingLotId} not found.");

            var exists = await _context.FavoriteParkingLots.AnyAsync(x =>
                x.UserId == request.UserId && x.ParkingLotId == request.ParkingLotId);
            if (exists) throw new BusinessException("Parking lot is already in favorites.");

            var entity = new FavoriteParkingLot
            {
                UserId = request.UserId,
                ParkingLotId = request.ParkingLotId,
                CreatedAt = DateTime.UtcNow
            };

            _context.FavoriteParkingLots.Add(entity);
            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task<FavoriteParkingLotResponse> UpdateAsync(FavoriteParkingLotUpdateRequest request)
        {
            var entity = await _context.FavoriteParkingLots.FindAsync(request.Id)
                ?? throw new NotFoundException($"FavoriteParkingLot with id {request.Id} not found.");

            entity.UserId = request.UserId;
            entity.ParkingLotId = request.ParkingLotId;
            await _context.SaveChangesAsync();

            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.FavoriteParkingLots.FindAsync(id)
                ?? throw new NotFoundException($"FavoriteParkingLot with id {id} not found.");
            _context.FavoriteParkingLots.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}

