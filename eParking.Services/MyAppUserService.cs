using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class MyAppUserService : IMyAppUserService
    {
        private readonly ParkingDbContext _context;

        public MyAppUserService(ParkingDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<MyAppUserResponse>> GetAllAsync(MyAppUserSearch? search = null)
        {
            var query = BuildQuery();
            query = ApplyFilters(query, search);
            return await query
                .OrderBy(u => u.Id)
                .Select(u => new MyAppUserResponse
                {
                    Id = u.Id,
                    Username = u.Username,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Email = u.Email,
                    IsActive = u.IsActive,
                    PhoneNumber = u.PhoneNumber,
                    GenderId = u.GenderId,
                    GenderName = u.Gender != null ? u.Gender.Name : null,
                    CityId = u.CityId,
                    CityName = u.City != null ? u.City.Name : null,
                    IsAdmin = u.IsAdmin,
                    IsUser = u.IsUser,
                    CreatedAt = u.CreatedAt,
                    UpdatedAt = u.UpdatedAt,
                    CarCount = u.Cars.Count
                })
                .ToPagedAsync(search);
        }

        public async Task<MyAppUserResponse> GetByIdAsync(int id)
        {
            var user = await BuildQuery().FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
                throw new NotFoundException($"User with id {id} not found.");

            return MapToResponse(user);
        }

        public async Task<MyAppUserResponse> InsertAsync(MyAppUserInsertRequest request)
        {
            await ValidateUserAsync(request.Username, request.Email);
            await ValidateLookupsAsync(request.GenderId, request.CityId);

            PasswordHasher.CreateHash(request.Password, out var salt, out var hash);

            var entity = new MyAppUser
            {
                Username = request.Username.Trim(),
                PasswordSalt = salt,
                PasswordHash = hash,
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                Email = request.Email.Trim(),
                PhoneNumber = request.PhoneNumber,
                GenderId = request.GenderId,
                CityId = request.CityId,
                IsAdmin = request.IsAdmin,
                IsUser = request.IsUser,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.MyAppUsers.Add(entity);
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(u => u.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task<MyAppUserResponse> UpdateAsync(MyAppUserUpdateRequest request)
        {
            var entity = await _context.MyAppUsers.FindAsync(request.Id);
            if (entity == null)
                throw new NotFoundException($"User with id {request.Id} not found.");

            await ValidateUserAsync(request.Username, request.Email, request.Id);
            await ValidateLookupsAsync(request.GenderId, request.CityId);

            entity.Username = request.Username.Trim();
            entity.FirstName = request.FirstName.Trim();
            entity.LastName = request.LastName.Trim();
            entity.Email = request.Email.Trim();
            entity.PhoneNumber = request.PhoneNumber;
            entity.GenderId = request.GenderId;
            entity.CityId = request.CityId;
            entity.IsAdmin = request.IsAdmin;
            entity.IsUser = request.IsUser;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                PasswordHasher.CreateHash(request.Password, out var salt, out var hash);
                entity.PasswordSalt = salt;
                entity.PasswordHash = hash;
            }

            await _context.SaveChangesAsync();
            entity = await BuildQuery().FirstAsync(u => u.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task ChangePasswordAsync(int userId, string currentPassword, string newPassword)
        {
            var entity = await _context.MyAppUsers.FindAsync(userId);
            if (entity == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (string.IsNullOrWhiteSpace(currentPassword))
                throw new BusinessException("Trenutna lozinka je obavezna.");

            if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length < 6)
                throw new BusinessException("Nova lozinka mora imati najmanje 6 znakova.");

            if (!PasswordHasher.Verify(currentPassword, entity.PasswordSalt, entity.PasswordHash))
                throw new UnauthorizedAccessException("Trenutna lozinka nije ispravna.");

            PasswordHasher.CreateHash(newPassword, out var salt, out var hash);
            entity.PasswordSalt = salt;
            entity.PasswordHash = hash;
            entity.FailedLoginAttempts = 0;
            entity.LockoutUntil = null;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        public async Task<MyAppUserResponse> UpdateProfilePictureAsync(int userId, string? pictureBase64)
        {
            var entity = await _context.MyAppUsers.FindAsync(userId);
            if (entity == null)
                throw new NotFoundException($"User with id {userId} not found.");

            entity.Picture = string.IsNullOrWhiteSpace(pictureBase64)
                ? null
                : BinaryFieldHelper.FromApiImageString(pictureBase64);
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(u => u.Id == userId);
            return MapToResponse(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.MyAppUsers
                .Include(u => u.Cars)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (entity == null)
                throw new NotFoundException($"User with id {id} not found.");

            if (entity.Cars.Any())
                throw new BusinessException("Cannot delete a user that has registered cars.");

            _context.MyAppUsers.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private IQueryable<MyAppUser> BuildQuery()
        {
            return _context.MyAppUsers
                .AsNoTracking()
                .Include(u => u.Gender)
                .Include(u => u.City)
                .Include(u => u.Cars);
        }

        private static IQueryable<MyAppUser> ApplyFilters(IQueryable<MyAppUser> query, MyAppUserSearch? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(u =>
                    u.FirstName.Contains(search.Name) ||
                    u.LastName.Contains(search.Name));
            }

            if (search.IsAdmin.HasValue)
                query = query.Where(u => u.IsAdmin == search.IsAdmin.Value);

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            return query;
        }

        private async Task ValidateUserAsync(string username, string email, int? excludeId = null)
        {
            var exists = await _context.MyAppUsers.AnyAsync(u =>
                (u.Username == username.Trim() || u.Email == email.Trim()) &&
                (!excludeId.HasValue || u.Id != excludeId.Value));

            if (exists)
                throw new BusinessException(
                    "Korisničko ime ili e-mail adresa su već u upotrebi — unesite druge vrijednosti.");
        }

        private async Task ValidateLookupsAsync(int? genderId, int? cityId)
        {
            if (genderId.HasValue && !await _context.Genders.AnyAsync(g => g.Id == genderId.Value))
                throw new NotFoundException($"Gender with id {genderId} not found.");

            if (cityId.HasValue && !await _context.Cities.AnyAsync(c => c.Id == cityId.Value))
                throw new NotFoundException($"City with id {cityId} not found.");
        }

        private static MyAppUserResponse MapToResponse(MyAppUser user)
        {
            return new MyAppUserResponse
            {
                Id = user.Id,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                IsActive = user.IsActive,
                PhoneNumber = user.PhoneNumber,
                GenderId = user.GenderId,
                GenderName = user.Gender?.Name,
                CityId = user.CityId,
                CityName = user.City?.Name,
                IsAdmin = user.IsAdmin,
                IsUser = user.IsUser,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                CarCount = user.Cars?.Count ?? 0,
                Picture = BinaryFieldHelper.ToApiString(user.Picture),
            };
        }
    }
}
