using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public static class PaginationHelper
    {
        public const int MaxPageSize = 100;
        public const int DefaultPageSize = 20;

        public static (int Page, int PageSize, int Skip) Normalize(PagedSearch? search)
        {
            search ??= new PagedSearch();
            var page = search.Page < 1 ? 1 : search.Page;
            var pageSize = search.PageSize < 1 ? DefaultPageSize : Math.Min(search.PageSize, MaxPageSize);
            return (page, pageSize, (page - 1) * pageSize);
        }

        public static async Task<PagedResponse<T>> ToPagedAsync<T>(
            this IQueryable<T> query,
            PagedSearch? search,
            CancellationToken cancellationToken = default)
        {
            var (page, pageSize, skip) = Normalize(search);
            var total = await query.CountAsync(cancellationToken);
            var items = await query.Skip(skip).Take(pageSize).ToListAsync(cancellationToken);
            return new PagedResponse<T>
            {
                Items = items,
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public static PagedResponse<T> FromList<T>(IReadOnlyList<T> source, PagedSearch? search)
        {
            var (page, pageSize, skip) = Normalize(search);
            var items = source.Skip(skip).Take(pageSize).ToList();
            return new PagedResponse<T>
            {
                Items = items,
                TotalCount = source.Count,
                Page = page,
                PageSize = pageSize
            };
        }
    }
}
