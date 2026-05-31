using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using eParking.Model;
using eParking.Services.Database.Parking;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace eParking.Services
{
    public interface IJwtTokenService
    {
        (string Token, DateTime ExpiresAt) CreateToken(MyAppUser user);
    }

    public class JwtTokenService : IJwtTokenService
    {
        private readonly JwtSettings _settings;

        public JwtTokenService(IOptions<JwtSettings> settings)
        {
            _settings = settings.Value;
        }

        public (string Token, DateTime ExpiresAt) CreateToken(MyAppUser user)
        {
            var expiresAt = DateTime.UtcNow.AddMinutes(_settings.ExpiresMinutes);
            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Name, user.Username),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Role, user.IsAdmin ? AppRoles.Admin : AppRoles.User),
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Key));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var token = new JwtSecurityToken(
                issuer: _settings.Issuer,
                audience: _settings.Audience,
                claims: claims,
                expires: expiresAt,
                signingCredentials: credentials);

            return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
        }
    }
}
