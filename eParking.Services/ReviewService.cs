using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IReviewService : IBaseCRUDService<ReviewResponse, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest> { }

    public class ReviewService : IReviewService
    {
        private readonly ParkingDbContext _context;

        public ReviewService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<ReviewResponse>> GetAllAsync(ReviewSearch? search = null)
        {
            var query = _context.Reviews
                .AsNoTracking()
                .Include(r => r.User)
                .Include(r => r.ParkingLot)
                .AsQueryable();

            if (search?.UserId.HasValue == true)
                query = query.Where(r => r.UserId == search.UserId.Value);
            if (search?.ParkingLotId.HasValue == true)
                query = query.Where(r => r.ParkingLotId == search.ParkingLotId.Value);
            if (search?.MinRating.HasValue == true)
                query = query.Where(r => r.Rating >= search.MinRating.Value);

            return await query
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new ReviewResponse
                {
                    Id = r.Id,
                    UserId = r.UserId,
                    UserFullName = r.User != null ? (r.User.FirstName + " " + r.User.LastName) : string.Empty,
                    ParkingLotId = r.ParkingLotId,
                    ParkingLotName = r.ParkingLot != null ? r.ParkingLot.Name : string.Empty,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<ReviewResponse> GetByIdAsync(int id)
        {
            var r = await _context.Reviews.AsNoTracking()
                .Include(x => x.User)
                .Include(x => x.ParkingLot)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException($"Review with id {id} not found.");

            return new ReviewResponse
            {
                Id = r.Id,
                UserId = r.UserId,
                UserFullName = r.User != null ? (r.User.FirstName + " " + r.User.LastName) : string.Empty,
                ParkingLotId = r.ParkingLotId,
                ParkingLotName = r.ParkingLot?.Name ?? string.Empty,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            };
        }

        public async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
        {
            await ValidateAsync(request.UserId, request.ParkingLotId, request.Rating, request.Comment);
            await EnsureCompletedReservationAsync(request.UserId, request.ParkingLotId);

            var exists = await _context.Reviews.AnyAsync(r => r.UserId == request.UserId && r.ParkingLotId == request.ParkingLotId);
            if (exists)
                throw new BusinessException("Recenzija za ovu parking lokaciju već postoji.");

            var entity = new Review
            {
                UserId = request.UserId,
                ParkingLotId = request.ParkingLotId,
                Rating = request.Rating,
                Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim(),
                CreatedAt = DateTime.UtcNow
            };
            _context.Reviews.Add(entity);
            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task<ReviewResponse> UpdateAsync(ReviewUpdateRequest request)
        {
            await ValidateAsync(request.UserId, request.ParkingLotId, request.Rating, request.Comment);

            var entity = await _context.Reviews.FindAsync(request.Id)
                ?? throw new NotFoundException($"Review with id {request.Id} not found.");

            entity.UserId = request.UserId;
            entity.ParkingLotId = request.ParkingLotId;
            entity.Rating = request.Rating;
            entity.Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Reviews.FindAsync(id)
                ?? throw new NotFoundException($"Review with id {id} not found.");
            _context.Reviews.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private async Task ValidateAsync(int userId, int parkingLotId, int rating, string? comment)
        {
            if (rating < 1 || rating > 5)
                throw new BusinessException("Ocjena mora biti u rasponu od 1 do 5.");

            var userExists = await _context.MyAppUsers.AnyAsync(u => u.Id == userId);
            if (!userExists) throw new NotFoundException($"User with id {userId} not found.");

            var lotExists = await _context.ParkingLots.AnyAsync(l => l.Id == parkingLotId);
            if (!lotExists) throw new NotFoundException($"ParkingLot with id {parkingLotId} not found.");

            if (comment != null && comment.Length > 1000)
                throw new BusinessException("Komentar smije imati najviše 1000 znakova.");
        }

        private async Task EnsureCompletedReservationAsync(int userId, int parkingLotId)
        {
            var hasCompleted = await _context.Reservations.AnyAsync(r =>
                r.Car.UserId == userId &&
                r.Status == (int)ReservationStatus.Completed &&
                r.ParkingSpot.Zone.ParkingLotId == parkingLotId);

            if (!hasCompleted)
                throw new BusinessException(
                    "Recenziju možete ostaviti tek nakon završene rezervacije na ovoj lokaciji.");
        }
    }
}

