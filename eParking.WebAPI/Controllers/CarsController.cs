using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[Authorize]
public class CarsController
    : BaseCRUDController<CarResponse, CarSearch, CarInsertRequest, CarUpdateRequest, ICarService>
{
    private readonly ICurrentUserService _currentUser;

    public CarsController(ICarService service, ICurrentUserService currentUser) : base(service)
    {
        _currentUser = currentUser;
    }

    public override async Task<PagedResponse<CarResponse>> GetAll([FromQuery] CarSearch? search)
    {
        search ??= new CarSearch();
        if (!_currentUser.IsAdmin)
            search.UserId = _currentUser.GetUserId();

        return await base.GetAll(search);
    }

    public override async Task<ActionResult<CarResponse>> GetById(int id)
    {
        var car = await _service.GetByIdAsync(id);
        EnsureCanAccess(car.UserId);
        return Ok(car);
    }

    public override async Task<ActionResult<CarResponse>> Create([FromBody] CarInsertRequest request)
    {
        if (!_currentUser.IsAdmin)
            request.UserId = _currentUser.GetUserId();

        return await base.Create(request);
    }

    public override async Task<ActionResult<CarResponse>> Update(int id, [FromBody] CarUpdateRequest request)
    {
        var existing = await _service.GetByIdAsync(id);
        EnsureCanAccess(existing.UserId);

        if (!_currentUser.IsAdmin)
            request.UserId = _currentUser.GetUserId();

        return await base.Update(id, request);
    }

    public override async Task<IActionResult> Delete(int id)
    {
        var existing = await _service.GetByIdAsync(id);
        EnsureCanAccess(existing.UserId);
        return await base.Delete(id);
    }

    private void EnsureCanAccess(int ownerUserId)
    {
        if (!_currentUser.IsAdmin && ownerUserId != _currentUser.GetUserId())
            throw new ForbiddenException("You can only access your own cars.");
    }
}
