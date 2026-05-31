using eParking.Model.Responses;
using System.Threading.Tasks;

namespace eParking.Services
{
    public interface IBaseReadService<TResponse, TSearch>
        where TSearch : class
    {
        Task<TResponse> GetByIdAsync(int id);
        Task<PagedResponse<TResponse>> GetAllAsync(TSearch? search = null);
    }
}
