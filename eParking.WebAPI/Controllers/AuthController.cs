using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ITokenRevocationService _tokenRevocation;

    public AuthController(IAuthService authService, ITokenRevocationService tokenRevocation)
    {
        _authService = authService;
        _tokenRevocation = tokenRevocation;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        => Ok(await _authService.LoginAsync(request, requireAdmin: false));

    [HttpPost("admin-login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<LoginResponse>> AdminLogin([FromBody] LoginRequest request)
        => Ok(await _authService.LoginAsync(request, requireAdmin: true));

    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<LoginResponse>> Register([FromBody] RegisterRequest request)
        => Ok(await _authService.RegisterAsync(request));

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ForgotPasswordResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ForgotPasswordResponse>> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var includeDevCode = HttpContext.RequestServices
            .GetRequiredService<IHostEnvironment>()
            .IsDevelopment();
        return Ok(await _authService.ForgotPasswordAsync(request, includeDevCode));
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        await _authService.ResetPasswordAsync(request);
        return NoContent();
    }

    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public IActionResult Logout()
    {
        var jti = User.FindFirstValue(JwtRegisteredClaimNames.Jti);
        var expClaim = User.FindFirstValue(JwtRegisteredClaimNames.Exp);
        if (!string.IsNullOrEmpty(jti) && long.TryParse(expClaim, out var expUnix))
        {
            var expiresAt = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;
            _tokenRevocation.Revoke(jti, expiresAt);
        }

        return NoContent();
    }
}
