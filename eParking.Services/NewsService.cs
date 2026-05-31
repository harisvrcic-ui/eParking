using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface INewsService
        : IBaseCRUDService<NewsResponse, NewsSearch, NewsInsertRequest, NewsUpdateRequest> { }

    public class NewsService : INewsService
    {
        private readonly ParkingDbContext _context;

        public NewsService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<NewsResponse>> GetAllAsync(NewsSearch? search = null)
        {
            var query = _context.NewsItems.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(search?.Title))
                query = query.Where(n => n.Title.Contains(search.Title));
            if (search?.IsActive.HasValue == true)
                query = query.Where(n => n.IsActive == search.IsActive.Value);

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NewsResponse
                {
                    Id = n.Id,
                    Title = n.Title,
                    Body = n.Body,
                    Image = null,
                    HasImage = n.Image != null && n.Image.Length > 0,
                    IsActive = n.IsActive,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt
                })
                .ToPagedAsync(search);
        }

        public async Task<NewsResponse> GetByIdAsync(int id)
        {
            var entity = await _context.NewsItems.AsNoTracking().FirstOrDefaultAsync(n => n.Id == id)
                ?? throw new NotFoundException($"News item with id {id} not found.");
            return Map(entity);
        }

        public async Task<NewsResponse> InsertAsync(NewsInsertRequest request)
        {
            ValidateRequest(request.Title, request.Body);
            if (string.IsNullOrWhiteSpace(request.Image))
                throw new BusinessException("News image is required.");

            var entity = new NewsItem
            {
                Title = request.Title.Trim(),
                Body = request.Body.Trim(),
                Image = BinaryFieldHelper.FromApiImageString(request.Image),
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.NewsItems.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<NewsResponse> UpdateAsync(NewsUpdateRequest request)
        {
            ValidateRequest(request.Title, request.Body);

            var entity = await _context.NewsItems.FindAsync(request.Id)
                ?? throw new NotFoundException($"News item with id {request.Id} not found.");

            entity.Title = request.Title.Trim();
            entity.Body = request.Body.Trim();
            if (!string.IsNullOrWhiteSpace(request.Image))
                entity.Image = BinaryFieldHelper.FromApiImageString(request.Image);
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.NewsItems.FindAsync(id)
                ?? throw new NotFoundException($"News item with id {id} not found.");
            _context.NewsItems.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static void ValidateRequest(string title, string body)
        {
            if (string.IsNullOrWhiteSpace(title))
                throw new BusinessException("Title is required.");
            if (string.IsNullOrWhiteSpace(body))
                throw new BusinessException("Body is required.");
        }

        private static NewsResponse Map(NewsItem n) => new()
        {
            Id = n.Id,
            Title = n.Title,
            Body = n.Body,
            Image = BinaryFieldHelper.ToApiString(n.Image),
            HasImage = n.Image != null && n.Image.Length > 0,
            IsActive = n.IsActive,
            CreatedAt = n.CreatedAt,
            UpdatedAt = n.UpdatedAt
        };
    }
}
