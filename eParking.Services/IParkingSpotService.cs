using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface IParkingSpotService : IBaseCRUDService<ParkingSpotResponse, ParkingSpotSearch, ParkingSpotInsertRequest, ParkingSpotUpdateRequest>
    {
        Task<PagedResponse<ParkingSpotResponse>> GetAvailableAsync(ParkingSpotAvailabilitySearch search);
    }
}
