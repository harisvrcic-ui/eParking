using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class ReservationTypesController
    : BaseCRUDController<ReservationTypeResponse, ReservationTypeSearch, ReservationTypeInsertRequest, ReservationTypeUpdateRequest, IReservationTypeService>
{
    public ReservationTypesController(IReservationTypeService service) : base(service) { }
}
