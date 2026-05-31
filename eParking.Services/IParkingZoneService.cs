using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface IParkingZoneService : IBaseCRUDService<ParkingZoneResponse, ParkingZoneSearch, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>
    {
    }
}
