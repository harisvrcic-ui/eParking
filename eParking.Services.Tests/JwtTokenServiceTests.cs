using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using eParking.Model;
using eParking.Services;
using eParking.Services.Database.Parking;
using Microsoft.Extensions.Options;

namespace eParking.Services.Tests;

public class JwtTokenServiceTests
{
    private static readonly JwtSettings Settings = new()
    {
        Key = "test-signing-key-must-be-at-least-32-bytes-long",
        Issuer = "eParking.Tests",
        Audience = "eParking.Tests",
        ExpiresMinutes = 60,
    };

    private static JwtTokenService CreateService() =>
        new(Options.Create(Settings));

    private static MyAppUser CreateUser(bool isAdmin, bool isUser, bool isActive = true) => new()
    {
        Id = 1,
        Username = "test",
        Email = "test@example.com",
        IsAdmin = isAdmin,
        IsUser = isUser,
        IsActive = isActive,
    };

    private static List<string> ReadRoleClaims(string token)
    {
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);
        return jwt.Claims
            .Where(c => c.Type == ClaimTypes.Role)
            .Select(c => c.Value)
            .ToList();
    }

    [Fact]
    public void CreateToken_adds_only_user_role_when_not_admin()
    {
        var (token, _) = CreateService().CreateToken(CreateUser(isAdmin: false, isUser: true));

        Assert.Equal([AppRoles.User], ReadRoleClaims(token));
    }

    [Fact]
    public void CreateToken_adds_both_roles_when_admin_and_user()
    {
        var (token, _) = CreateService().CreateToken(CreateUser(isAdmin: true, isUser: true));

        Assert.Equal([AppRoles.Admin, AppRoles.User], ReadRoleClaims(token));
    }

    [Fact]
    public void CreateToken_adds_only_admin_role_when_user_flag_false()
    {
        var (token, _) = CreateService().CreateToken(CreateUser(isAdmin: true, isUser: false));

        Assert.Equal([AppRoles.Admin], ReadRoleClaims(token));
    }

    [Fact]
    public void CreateToken_throws_when_user_has_no_roles()
    {
        Assert.Throws<UnauthorizedAccessException>(() =>
            CreateService().CreateToken(CreateUser(isAdmin: false, isUser: false)));
    }

    [Fact]
    public void CreateToken_throws_when_user_is_inactive()
    {
        Assert.Throws<UnauthorizedAccessException>(() =>
            CreateService().CreateToken(CreateUser(isAdmin: true, isUser: true, isActive: false)));
    }
}
