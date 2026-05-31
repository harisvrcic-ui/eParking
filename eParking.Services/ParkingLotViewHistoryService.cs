using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IParkingLotViewHistoryService
        : IBaseCRUDService<ParkingLotViewHistoryResponse, ParkingLotViewHistorySearch, ParkingLotViewHistoryInsertRequest, ParkingLotViewHistoryUpdateRequest>
    {
        Task<ParkingLotViewHistoryResponse> RecordViewAsync(int userId, int parkingLotId);
    }

    public class ParkingLotViewHistoryService : IParkingLotViewHistoryService
    {
        private readonly ParkingDbContext _context;

        public ParkingLotViewHistoryService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<ParkingLotViewHistoryResponse>> GetAllAsync(ParkingLotViewHistorySearch? search = null)
        {
            var query = _context.ParkingLotViewHistories
                .AsNoTracking()
                .Include(x => x.User)
                .Include(x => x.ParkingLot)
                .AsQueryable();

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId.Value);
            if (search?.ParkingLotId.HasValue == true)
                query = query.Where(x => x.ParkingLotId == search.ParkingLotId.Value);

            return await query
                .OrderByDescending(x => x.LastViewedAt)
                .Select(x => new ParkingLotViewHistoryResponse
                {
                    Id = x.Id,
                    UserId = x.UserId,
                    UserFullName = x.User != null ? (x.User.FirstName + " " + x.User.LastName) : string.Empty,
                    ParkingLotId = x.ParkingLotId,
                    ParkingLotName = x.ParkingLot != null ? x.ParkingLot.Name : string.Empty,
                    ViewCount = x.ViewCount,
                    LastViewedAt = x.LastViewedAt,
                    CreatedAt = x.CreatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<ParkingLotViewHistoryResponse> GetByIdAsync(int id)
        {
            var entity = await _context.ParkingLotViewHistories
                .AsNoTracking()
                .Include(x => x.User)
                .Include(x => x.ParkingLot)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException($"ParkingLotViewHistory with id {id} not found.");

            return Map(entity);
        }

        public async Task<ParkingLotViewHistoryResponse> InsertAsync(ParkingLotViewHistoryInsertRequest request)
        {
            await ValidateAsync(request.UserId, request.ParkingLotId, request.ViewCount);

            var exists = await _context.ParkingLotViewHistories.AnyAsync(x =>
                x.UserId == request.UserId && x.ParkingLotId == request.ParkingLotId);
            if (exists)
                throw new BusinessException("View history already exists for this user and parking lot. Use update or record endpoint.");

            var now = DateTime.UtcNow;
            var entity = new ParkingLotViewHistory
            {
                UserId = request.UserId,
                ParkingLotId = request.ParkingLotId,
                ViewCount = request.ViewCount < 1 ? 1 : request.ViewCount,
                LastViewedAt = now,
                CreatedAt = now
            };
            _context.ParkingLotViewHistories.Add(entity);
            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task<ParkingLotViewHistoryResponse> UpdateAsync(ParkingLotViewHistoryUpdateRequest request)
        {
            await ValidateAsync(request.UserId, request.ParkingLotId, request.ViewCount);

            var entity = await _context.ParkingLotViewHistories.FindAsync(request.Id)
                ?? throw new NotFoundException($"ParkingLotViewHistory with id {request.Id} not found.");

            entity.UserId = request.UserId;
            entity.ParkingLotId = request.ParkingLotId;
            entity.ViewCount = request.ViewCount < 1 ? 1 : request.ViewCount;
            entity.LastViewedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.ParkingLotViewHistories.FindAsync(id)
                ?? throw new NotFoundException($"ParkingLotViewHistory with id {id} not found.");
            _context.ParkingLotViewHistories.Remove(entity);
            await _context.SaveChangesAsync();
        }

        public async Task<ParkingLotViewHistoryResponse> RecordViewAsync(int userId, int parkingLotId)
        {
            await ValidateAsync(userId, parkingLotId, 1);

            var entity = await _context.ParkingLotViewHistories
                .FirstOrDefaultAsync(x => x.UserId == userId && x.ParkingLotId == parkingLotId);

            var now = DateTime.UtcNow;
            if (entity == null)
            {
                entity = new ParkingLotViewHistory
                {
                    UserId = userId,
                    ParkingLotId = parkingLotId,
                    ViewCount = 1,
                    LastViewedAt = now,
                    CreatedAt = now
                };
                _context.ParkingLotViewHistories.Add(entity);
            }
            else
            {
                entity.ViewCount++;
                entity.LastViewedAt = now;
            }

            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        private async Task ValidateAsync(int userId, int parkingLotId, int viewCount)
        {
            if (viewCount < 1)
                throw new BusinessException("View count must be at least 1.");

            if (!await _context.MyAppUsers.AnyAsync(u => u.Id == userId))
                throw new NotFoundException($"User with id {userId} not found.");

            if (!await _context.ParkingLots.AnyAsync(l => l.Id == parkingLotId))
                throw new NotFoundException($"ParkingLot with id {parkingLotId} not found.");
        }

        private static ParkingLotViewHistoryResponse Map(ParkingLotViewHistory x) => new()
        {
            Id = x.Id,
            UserId = x.UserId,
            UserFullName = x.User != null ? (x.User.FirstName + " " + x.User.LastName) : string.Empty,
            ParkingLotId = x.ParkingLotId,
            ParkingLotName = x.ParkingLot?.Name ?? string.Empty,
            ViewCount = x.ViewCount,
            LastViewedAt = x.LastViewedAt,
            CreatedAt = x.CreatedAt
        };
    }
}
