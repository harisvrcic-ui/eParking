using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class AccountController : ControllerBase
{
    private readonly IMyAppUserService _userService;
    private readonly ICurrentUserService _currentUser;

    public AccountController(IMyAppUserService userService, ICurrentUserService currentUser)
    {
        _userService = userService;
        _currentUser = currentUser;
    }

    [HttpGet("me")]
    [ProducesResponseType(typeof(MyAppUserResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<MyAppUserResponse>> GetMe()
        => Ok(await _userService.GetByIdAsync(_currentUser.GetUserId()));

    [HttpPut("me")]
    [ProducesResponseType(typeof(MyAppUserResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<MyAppUserResponse>> UpdateMe([FromBody] MyProfileUpdateRequest request)
    {
        var existing = await _userService.GetByIdAsync(_currentUser.GetUserId());
        var update = new MyAppUserUpdateRequest
        {
            Id = _currentUser.GetUserId(),
            Username = request.Username,
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            GenderId = request.GenderId ?? existing.GenderId,
            CityId = request.CityId ?? existing.CityId,
            IsAdmin = existing.IsAdmin,
            IsUser = existing.IsUser,
            IsActive = existing.IsActive,
        };

        return Ok(await _userService.UpdateAsync(update));
    }

    [HttpPut("me/picture")]
    [ProducesResponseType(typeof(MyAppUserResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<MyAppUserResponse>> UpdatePicture(
        [FromBody] MyProfilePictureUpdateRequest request)
        => Ok(await _userService.UpdateProfilePictureAsync(_currentUser.GetUserId(), request.Picture));

    [HttpPut("me/password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword([FromBody] MyProfileChangePasswordRequest request)
    {
        await _userService.ChangePasswordAsync(
            _currentUser.GetUserId(),
            request.CurrentPassword,
            request.NewPassword);
        return NoContent();
    }
}
