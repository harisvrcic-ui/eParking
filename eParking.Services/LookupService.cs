using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace eParking.Services
{
    public class LookupService : ILookupService
    {
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(10);

        private readonly ParkingDbContext _context;
        private readonly IMemoryCache _cache;

        public LookupService(ParkingDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        public Task<PagedResponse<LookupItemResponse>> GetGendersAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:genders", () =>
                _context.Genders
                    .Where(g => g.IsActive)
                    .OrderBy(g => g.Name)
                    .Select(g => new LookupItemResponse { Id = g.Id, Name = g.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetCountriesAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:countries", () =>
                _context.Countries
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.Name)
                    .Select(c => new LookupItemResponse { Id = c.Id, Name = c.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetCitiesAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:cities", () =>
                _context.Cities
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.Name)
                    .Select(c => new LookupItemResponse { Id = c.Id, Name = c.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetBrandsAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:brands", () =>
                _context.Brands
                    .Where(b => b.IsActive)
                    .OrderBy(b => b.Name)
                    .Select(b => new LookupItemResponse { Id = b.Id, Name = b.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetColorsAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:colors", () =>
                _context.Colors
                    .OrderBy(c => c.Name)
                    .Select(c => new LookupItemResponse { Id = c.Id, Name = c.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetParkingSpotTypesAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:parking-spot-types", () =>
                _context.ParkingSpotTypes
                    .OrderBy(t => t.Name)
                    .Select(t => new LookupItemResponse { Id = t.Id, Name = t.Name })
                    .ToListAsync(), search);

        public Task<PagedResponse<LookupItemResponse>> GetReservationTypesAsync(LookupSearch? search = null)
            => GetCachedAsync("lookup:reservation-types", () =>
                _context.ReservationTypes
                    .OrderBy(t => t.Name)
                    .Select(t => new LookupItemResponse { Id = t.Id, Name = t.Name })
                    .ToListAsync(), search);

        private async Task<PagedResponse<LookupItemResponse>> GetCachedAsync(
            string cacheKey,
            Func<Task<List<LookupItemResponse>>> loadAsync,
            LookupSearch? search)
        {
            var list = await _cache.GetOrCreateAsync(cacheKey, async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = CacheDuration;
                return await loadAsync();
            });

            return PaginationHelper.FromList(list ?? [], search);
        }
    }
}
