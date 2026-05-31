using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class ParkingLotViewHistoriesController : ControllerBase
{
    private readonly IParkingLotViewHistoryService _service;
    private readonly ICurrentUserService _currentUser;

    public ParkingLotViewHistoriesController(IParkingLotViewHistoryService service, ICurrentUserService currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<PagedResponse<ParkingLotViewHistoryResponse>> GetAll([FromQuery] ParkingLotViewHistorySearch? search)
        => await _service.GetAllAsync(search);

    [HttpGet("my")]
    public async Task<PagedResponse<ParkingLotViewHistoryResponse>> GetMy([FromQuery] ParkingLotViewHistorySearch? search)
    {
        search ??= new ParkingLotViewHistorySearch();
        search.UserId = _currentUser.GetUserId();
        return await _service.GetAllAsync(search);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ParkingLotViewHistoryResponse>> GetById(int id)
    {
        var item = await _service.GetByIdAsync(id);
        if (!_currentUser.IsAdmin && item.UserId != _currentUser.GetUserId())
            throw new ForbiddenException("You cannot access other user's view history.");
        return Ok(item);
    }

    [HttpPost("record")]
    public async Task<ActionResult<ParkingLotViewHistoryResponse>> RecordView([FromBody] ParkingLotViewHistoryRecordRequest request)
        => Ok(await _service.RecordViewAsync(_currentUser.GetUserId(), request.ParkingLotId));

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<ParkingLotViewHistoryResponse>> Create([FromBody] ParkingLotViewHistoryInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<ParkingLotViewHistoryResponse>> Update(int id, [FromBody] ParkingLotViewHistoryUpdateRequest request)
    {
        request.Id = id;
        return Ok(await _service.UpdateAsync(request));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
