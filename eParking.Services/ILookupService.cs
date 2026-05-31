using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface ILookupService
    {
        Task<PagedResponse<LookupItemResponse>> GetGendersAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetCountriesAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetCitiesAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetBrandsAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetColorsAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetParkingSpotTypesAsync(LookupSearch? search = null);
        Task<PagedResponse<LookupItemResponse>> GetReservationTypesAsync(LookupSearch? search = null);
    }
}
