using eParking.Model.Exceptions;

using eParking.Model;
using eParking.Model.Requests;

using eParking.Model.Responses;

using eParking.Model.SearchObjects;

using eParking.Services;

using Microsoft.AspNetCore.Authorization;

using Microsoft.AspNetCore.Mvc;



namespace eParking.WebAPI.Controllers;



[Authorize]

public class ReservationsController

    : BaseCRUDController<ReservationResponse, ReservationSearch, ReservationInsertRequest, ReservationUpdateRequest, IReservationService>

{

    private readonly ICurrentUserService _currentUser;

    private readonly ICarService _carService;



    public ReservationsController(

        IReservationService service,

        ICurrentUserService currentUser,

        ICarService carService) : base(service)

    {

        _currentUser = currentUser;

        _carService = carService;

    }



    public override async Task<PagedResponse<ReservationResponse>> GetAll([FromQuery] ReservationSearch? search)

    {

        search ??= new ReservationSearch();

        if (!_currentUser.IsAdmin)

            search.UserId = _currentUser.GetUserId();



        return await base.GetAll(search);

    }



    public override async Task<ActionResult<ReservationResponse>> GetById(int id)

    {

        var reservation = await _service.GetByIdAsync(id);

        EnsureCanAccess(reservation.UserId);

        return Ok(reservation);

    }



    public override async Task<ActionResult<ReservationResponse>> Create([FromBody] ReservationInsertRequest request)

    {

        var car = await _carService.GetByIdAsync(request.CarId);

        EnsureCanAccess(car.UserId);

        return await base.Create(request);

    }



    public override async Task<ActionResult<ReservationResponse>> Update(int id, [FromBody] ReservationUpdateRequest request)

    {

        var existing = await _service.GetByIdAsync(id);

        EnsureCanAccess(existing.UserId);



        var car = await _carService.GetByIdAsync(request.CarId);

        EnsureCanAccess(car.UserId);



        return await base.Update(id, request);

    }



    [HttpPost("{id}/cancel")]

    public async Task<ActionResult<ReservationResponse>> Cancel(int id, [FromBody] ReservationCancelRequest request)

    {

        var existing = await _service.GetByIdAsync(id);

        EnsureCanAccess(existing.UserId);

        var result = await _service.CancelAsync(id, request, _currentUser.GetUserId(), _currentUser.IsAdmin);

        return Ok(result);

    }



    [HttpPost("{id}/confirm")]

    [Authorize(Roles = AppRoles.Admin)]

    public async Task<ActionResult<ReservationResponse>> Confirm(int id, [FromBody] ReservationConfirmRequest? request)

    {

        var result = await _service.ConfirmAsync(id, request, _currentUser.GetUserId());

        return Ok(result);

    }



    [HttpPost("{id}/reject")]

    [Authorize(Roles = AppRoles.Admin)]

    public async Task<ActionResult<ReservationResponse>> Reject(int id, [FromBody] ReservationRejectRequest request)

    {

        var result = await _service.RejectAsync(id, request, _currentUser.GetUserId());

        return Ok(result);

    }



    public override Task<IActionResult> Delete(int id)

    {

        throw new BusinessException(

            "Hard delete is not allowed. Use POST /Reservations/{id}/cancel or /reject.");

    }



    private void EnsureCanAccess(int ownerUserId)

    {

        if (!_currentUser.IsAdmin && ownerUserId != _currentUser.GetUserId())

            throw new ForbiddenException("You can only access your own reservations.");

    }

}


