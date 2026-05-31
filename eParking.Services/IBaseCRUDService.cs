using System.Threading.Tasks;

namespace eParking.Services
{
    public interface IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest> 
        : IBaseReadService<TResponse, TSearch>
        where TSearch : class
    {
        Task<TResponse> InsertAsync(TInsertRequest request);
        Task<TResponse> UpdateAsync(TUpdateRequest request);
        Task DeleteAsync(int id);
    }
}
