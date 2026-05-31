using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[Authorize]
public class ParkingLotsController
    : BaseCRUDController<ParkingLotResponse, ParkingLotSearch, ParkingLotInsertRequest, ParkingLotUpdateRequest, IParkingLotService>
{
    private readonly IParkingLotService _parkingLotService;

    public ParkingLotsController(IParkingLotService service) : base(service)
    {
        _parkingLotService = service;
    }

    [HttpGet("overview")]
    public async Task<PagedResponse<ParkingLotOverviewResponse>> GetOverview([FromQuery] ParkingLotSearch? search)
        => await _parkingLotService.GetOverviewAsync(search);

    [HttpGet("{id}/detail")]
    public async Task<ParkingLotDetailResponse> GetDetail(int id)
        => await _parkingLotService.GetDetailAsync(id);

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<ParkingLotResponse>> Create([FromBody] ParkingLotInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<ParkingLotResponse>> Update(int id, [FromBody] ParkingLotUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
