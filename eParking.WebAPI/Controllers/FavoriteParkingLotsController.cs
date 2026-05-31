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
public class FavoriteParkingLotsController : ControllerBase
{
    private readonly IFavoriteParkingLotService _service;
    private readonly ICurrentUserService _currentUser;

    public FavoriteParkingLotsController(IFavoriteParkingLotService service, ICurrentUserService currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet("my")]
    public async Task<PagedResponse<FavoriteParkingLotResponse>> GetMy([FromQuery] FavoriteParkingLotSearch? search)
    {
        search ??= new FavoriteParkingLotSearch();
        search.UserId = _currentUser.GetUserId();
        return await _service.GetAllAsync(search);
    }

    [HttpPost("my")]
    public async Task<ActionResult<FavoriteParkingLotResponse>> AddMy([FromBody] FavoriteParkingLotMyRequest request)
    {
        var result = await _service.InsertAsync(new FavoriteParkingLotInsertRequest
        {
            UserId = _currentUser.GetUserId(),
            ParkingLotId = request.ParkingLotId,
        });
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpDelete("my/{id}")]
    public async Task<IActionResult> RemoveMy(int id)
    {
        var existing = await _service.GetByIdAsync(id);
        if (existing.UserId != _currentUser.GetUserId())
            throw new ForbiddenException("You can only remove your own favorites.");
        await _service.DeleteAsync(id);
        return NoContent();
    }

    [HttpGet]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<PagedResponse<FavoriteParkingLotResponse>> GetAll([FromQuery] FavoriteParkingLotSearch? search)
        => await _service.GetAllAsync(search);

    [HttpGet("{id}")]
    public async Task<ActionResult<FavoriteParkingLotResponse>> GetById(int id)
    {
        var item = await _service.GetByIdAsync(id);
        if (!_currentUser.IsAdmin && item.UserId != _currentUser.GetUserId())
            throw new ForbiddenException("You cannot access other user's favorites.");
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<FavoriteParkingLotResponse>> Create([FromBody] FavoriteParkingLotInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<FavoriteParkingLotResponse>> Update(int id, [FromBody] FavoriteParkingLotUpdateRequest request)
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
