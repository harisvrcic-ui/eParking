using System.Security.Claims;
using eParking.Model;
using Microsoft.AspNetCore.Http;

namespace eParking.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public int GetUserId()
        {
            var claim = _httpContextAccessor.HttpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(claim) || !int.TryParse(claim, out var userId))
                throw new UnauthorizedAccessException("User id claim is missing.");
            return userId;
        }

        public bool IsInRole(string role) =>
            _httpContextAccessor.HttpContext?.User.IsInRole(role) ?? false;

        public bool IsAdmin => IsInRole(AppRoles.Admin);
    }
}
