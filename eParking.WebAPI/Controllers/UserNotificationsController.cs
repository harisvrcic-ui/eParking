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
public class UserNotificationsController : ControllerBase
{
    private readonly IUserNotificationService _service;
    private readonly ICurrentUserService _currentUser;

    public UserNotificationsController(IUserNotificationService service, ICurrentUserService currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet("my")]
    public async Task<PagedResponse<UserNotificationResponse>> GetMy([FromQuery] UserNotificationSearch? search)
    {
        search ??= new UserNotificationSearch();
        search.UserId = _currentUser.GetUserId();
        return await _service.GetAllAsync(search);
    }

    [HttpGet]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<PagedResponse<UserNotificationResponse>> GetAll([FromQuery] UserNotificationSearch? search)
        => await _service.GetAllAsync(search);

    [HttpGet("{id}")]
    public async Task<ActionResult<UserNotificationResponse>> GetById(int id)
    {
        var notification = await _service.GetByIdAsync(id);
        if (!_currentUser.IsAdmin && notification.UserId != _currentUser.GetUserId())
            throw new ForbiddenException("You cannot access other user's notifications.");
        return Ok(notification);
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<UserNotificationResponse>> Create([FromBody] UserNotificationInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<UserNotificationResponse>> Update(int id, [FromBody] UserNotificationUpdateRequest request)
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

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkRead(int id)
    {
        await _service.MarkAsReadAsync(id, _currentUser.GetUserId());
        return NoContent();
    }
}
