using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface IParkingLotService : IBaseCRUDService<ParkingLotResponse, ParkingLotSearch, ParkingLotInsertRequest, ParkingLotUpdateRequest>
    {
        Task RefreshSpotCountsAsync(bool persistChanges = true);
        Task<PagedResponse<ParkingLotOverviewResponse>> GetOverviewAsync(ParkingLotSearch? search = null);
        Task<ParkingLotDetailResponse> GetDetailAsync(int id);
    }
}
