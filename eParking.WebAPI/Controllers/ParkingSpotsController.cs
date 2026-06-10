using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[Authorize]
public class ParkingSpotsController
    : BaseCRUDController<ParkingSpotResponse, ParkingSpotSearch, ParkingSpotInsertRequest, ParkingSpotUpdateRequest, IParkingSpotService>
{
    private readonly IParkingSpotService _parkingSpotService;

    public ParkingSpotsController(IParkingSpotService service) : base(service)
    {
        _parkingSpotService = service;
    }

    [HttpGet("available")]
    public async Task<ActionResult<PagedResponse<ParkingSpotResponse>>> GetAvailable(
        [FromQuery] ParkingSpotAvailabilitySearch search)
        => Ok(await _parkingSpotService.GetAvailableAsync(search));

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<ParkingSpotResponse>> Create([FromBody] ParkingSpotInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<ParkingSpotResponse>> Update(int id, [FromBody] ParkingSpotUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = AppRoles.Admin)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
