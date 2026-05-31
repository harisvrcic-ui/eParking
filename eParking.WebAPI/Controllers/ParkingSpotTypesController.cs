using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class ParkingSpotTypesController
    : BaseCRUDController<ParkingSpotTypeResponse, ParkingSpotTypeSearch, ParkingSpotTypeInsertRequest, ParkingSpotTypeUpdateRequest, IParkingSpotTypeService>
{
    public ParkingSpotTypesController(IParkingSpotTypeService service) : base(service) { }
}
