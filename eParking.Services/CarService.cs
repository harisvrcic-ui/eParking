using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public class CarService : ICarService
    {
        private readonly ParkingDbContext _context;

        public CarService(ParkingDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResponse<CarResponse>> GetAllAsync(CarSearch? search = null)
        {
            var query = BuildQuery();
            query = ApplyFilters(query, search);
            return await query
                .OrderBy(c => c.Id)
                .Select(c => new CarResponse
                {
                    Id = c.Id,
                    BrandId = c.BrandId,
                    BrandName = c.Brand != null ? c.Brand.Name : string.Empty,
                    ColorId = c.ColorId,
                    ColorName = c.Color != null ? c.Color.Name : string.Empty,
                    UserId = c.UserId,
                    UserFullName = c.User != null ? (c.User.FirstName + " " + c.User.LastName).Trim() : string.Empty,
                    Model = c.Model,
                    LicensePlate = c.LicensePlate,
                    YearOfManufacture = c.YearOfManufacture,
                    Picture = null,
                    IsActive = c.IsActive,
                    CreatedAt = c.CreatedAt,
                    UpdatedAt = c.UpdatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<CarResponse> GetByIdAsync(int id)
        {
            var car = await BuildQuery().FirstOrDefaultAsync(c => c.Id == id);
            if (car == null)
                throw new NotFoundException($"Car with id {id} not found.");

            return MapToResponse(car);
        }

        public async Task<CarResponse> InsertAsync(CarInsertRequest request)
        {
            await ValidateReferencesAsync(request.BrandId, request.ColorId, request.UserId);
            await EnsureLicensePlateUniqueAsync(request.LicensePlate);

            var model = StringNormalization.TrimOrEmpty(request.Model);
            var licensePlate = StringNormalization.TrimOrEmpty(request.LicensePlate).ToUpperInvariant();

            var entity = new Car
            {
                BrandId = request.BrandId,
                ColorId = request.ColorId,
                UserId = request.UserId,
                Model = model,
                LicensePlate = licensePlate,
                // Legacy DB column is NOT NULL; default when mobile/form omits year.
                YearOfManufacture = request.YearOfManufacture ?? DateTime.UtcNow.Year,
                Picture = BinaryFieldHelper.FromApiImageString(request.Picture),
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Cars.Add(entity);
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(c => c.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task<CarResponse> UpdateAsync(CarUpdateRequest request)
        {
            var entity = await _context.Cars.FindAsync(request.Id);
            if (entity == null)
                throw new NotFoundException($"Car with id {request.Id} not found.");

            await ValidateReferencesAsync(request.BrandId, request.ColorId, request.UserId);
            await EnsureLicensePlateUniqueAsync(request.LicensePlate, request.Id);

            entity.BrandId = request.BrandId;
            entity.ColorId = request.ColorId;
            entity.UserId = request.UserId;
            entity.Model = StringNormalization.TrimOrEmpty(request.Model);
            entity.LicensePlate = StringNormalization.TrimOrEmpty(request.LicensePlate).ToUpperInvariant();
            entity.YearOfManufacture = request.YearOfManufacture ?? entity.YearOfManufacture ?? DateTime.UtcNow.Year;
            entity.Picture = BinaryFieldHelper.FromApiImageString(request.Picture);
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            entity = await BuildQuery().FirstAsync(c => c.Id == entity.Id);
            return MapToResponse(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.Cars
                .Include(c => c.Reservations)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (entity == null)
                throw new NotFoundException($"Car with id {id} not found.");

            if (entity.Reservations.Any())
                throw new BusinessException("Cannot delete a car that has reservations.");

            _context.Cars.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private IQueryable<Car> BuildQuery()
        {
            return _context.Cars
                .AsNoTracking()
                .Include(c => c.Brand)
                .Include(c => c.Color)
                .Include(c => c.User);
        }

        private static IQueryable<Car> ApplyFilters(IQueryable<Car> query, CarSearch? search)
        {
            if (search == null) return query;

            if (search.UserId.HasValue)
                query = query.Where(c => c.UserId == search.UserId.Value);

            if (search.BrandId.HasValue)
                query = query.Where(c => c.BrandId == search.BrandId.Value);

            if (!string.IsNullOrWhiteSpace(search.LicensePlate))
                query = query.Where(c => c.LicensePlate.Contains(search.LicensePlate));

            if (search.IsActive.HasValue)
                query = query.Where(c => c.IsActive == search.IsActive.Value);

            return query;
        }

        private async Task ValidateReferencesAsync(int brandId, int colorId, int userId)
        {
            if (!await _context.Brands.AnyAsync(b => b.Id == brandId))
                throw new NotFoundException($"Brand with id {brandId} not found.");

            if (!await _context.Colors.AnyAsync(c => c.Id == colorId))
                throw new NotFoundException($"Color with id {colorId} not found.");

            if (!await _context.MyAppUsers.AnyAsync(u => u.Id == userId))
                throw new NotFoundException($"User with id {userId} not found.");
        }

        private async Task EnsureLicensePlateUniqueAsync(string? licensePlate, int? excludeId = null)
        {
            var plate = StringNormalization.TrimOrEmpty(licensePlate).ToUpperInvariant();
            if (plate.Length == 0)
                throw new BusinessException("License plate is required.");
            var exists = await _context.Cars.AnyAsync(c =>
                c.LicensePlate == plate && (!excludeId.HasValue || c.Id != excludeId.Value));

            if (exists)
                throw new BusinessException($"License plate '{plate}' is already registered.");
        }

        private static CarResponse MapToResponse(Car car)
        {
            return new CarResponse
            {
                Id = car.Id,
                BrandId = car.BrandId,
                BrandName = car.Brand?.Name ?? string.Empty,
                ColorId = car.ColorId,
                ColorName = car.Color?.Name ?? string.Empty,
                UserId = car.UserId,
                UserFullName = $"{car.User?.FirstName} {car.User?.LastName}".Trim(),
                Model = car.Model,
                LicensePlate = car.LicensePlate,
                YearOfManufacture = car.YearOfManufacture,
                Picture = BinaryFieldHelper.ToApiString(car.Picture),
                IsActive = car.IsActive,
                CreatedAt = car.CreatedAt,
                UpdatedAt = car.UpdatedAt
            };
        }
    }
}
