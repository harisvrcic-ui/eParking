using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IUserNotificationService
        : IBaseCRUDService<UserNotificationResponse, UserNotificationSearch, UserNotificationInsertRequest, UserNotificationUpdateRequest>
    {
        Task MarkAsReadAsync(int id, int userId);
        Task<bool> ExistsDuplicateAsync(int userId, int? reservationId, string title);
    }

    public class UserNotificationService : IUserNotificationService
    {
        private readonly ParkingDbContext _context;

        public UserNotificationService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<UserNotificationResponse>> GetAllAsync(UserNotificationSearch? search = null)
        {
            var query = _context.UserNotifications
                .AsNoTracking()
                .Include(n => n.User)
                .AsQueryable();

            if (search?.UserId.HasValue == true)
                query = query.Where(n => n.UserId == search.UserId.Value);
            if (search?.IsRead.HasValue == true)
                query = query.Where(n => n.IsRead == search.IsRead.Value);

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new UserNotificationResponse
                {
                    Id = n.Id,
                    UserId = n.UserId,
                    UserFullName = n.User != null ? (n.User.FirstName + " " + n.User.LastName) : string.Empty,
                    Username = n.User != null ? n.User.Username : string.Empty,
                    ReservationId = n.ReservationId,
                    Title = n.Title,
                    Body = n.Body,
                    IsRead = n.IsRead,
                    CreatedAt = n.CreatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<bool> ExistsDuplicateAsync(int userId, int? reservationId, string title)
        {
            return await _context.UserNotifications.AnyAsync(n =>
                n.UserId == userId &&
                n.ReservationId == reservationId &&
                n.Title == title);
        }

        public async Task<UserNotificationResponse> GetByIdAsync(int id)
        {
            var n = await _context.UserNotifications.AsNoTracking()
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException($"Notification with id {id} not found.");

            return new UserNotificationResponse
            {
                Id = n.Id,
                UserId = n.UserId,
                UserFullName = n.User != null ? (n.User.FirstName + " " + n.User.LastName) : string.Empty,
                Username = n.User?.Username ?? string.Empty,
                ReservationId = n.ReservationId,
                Title = n.Title,
                Body = n.Body,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            };
        }

        public async Task<UserNotificationResponse> InsertAsync(UserNotificationInsertRequest request)
        {
            var userExists = await _context.MyAppUsers.AnyAsync(u => u.Id == request.UserId);
            if (!userExists) throw new NotFoundException($"User with id {request.UserId} not found.");

            if (request.ReservationId.HasValue)
            {
                var resExists = await _context.Reservations.AnyAsync(r => r.Id == request.ReservationId.Value);
                if (!resExists) throw new NotFoundException($"Reservation with id {request.ReservationId.Value} not found.");
            }

            if (string.IsNullOrWhiteSpace(request.Title))
                throw new BusinessException("Title is required.");
            if (string.IsNullOrWhiteSpace(request.Body))
                throw new BusinessException("Body is required.");

            var entity = new UserNotification
            {
                UserId = request.UserId,
                ReservationId = request.ReservationId,
                Title = request.Title.Trim(),
                Body = request.Body.Trim(),
                IsRead = request.IsRead,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserNotifications.Add(entity);
            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
        }

        public async Task<UserNotificationResponse> UpdateAsync(UserNotificationUpdateRequest request)
        {
            var entity = await _context.UserNotifications.FindAsync(request.Id)
                ?? throw new NotFoundException($"Notification with id {request.Id} not found.");

            entity.UserId = request.UserId;
            entity.ReservationId = request.ReservationId;
            entity.Title = request.Title.Trim();
            entity.Body = request.Body.Trim();
            entity.IsRead = request.IsRead;
            await _context.SaveChangesAsync();

            return await GetByIdAsync(entity.Id);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.UserNotifications.FindAsync(id)
                ?? throw new NotFoundException($"Notification with id {id} not found.");
            _context.UserNotifications.Remove(entity);
            await _context.SaveChangesAsync();
        }

        public async Task MarkAsReadAsync(int id, int userId)
        {
            var entity = await _context.UserNotifications.FindAsync(id)
                ?? throw new NotFoundException($"Notification with id {id} not found.");
            if (entity.UserId != userId)
                throw new ForbiddenException("You cannot modify other user's notifications.");

            if (!entity.IsRead)
            {
                entity.IsRead = true;
                await _context.SaveChangesAsync();
            }
        }
    }
}

