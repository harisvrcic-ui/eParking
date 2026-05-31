using eParking.Model.Requests;
using eParking.Model.Responses;

namespace eParking.Services
{
    public interface IAuthService
    {
        Task<LoginResponse> LoginAsync(LoginRequest request, bool requireAdmin = false);
        Task<LoginResponse> RegisterAsync(RegisterRequest request);
        Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request, bool includeDevCode);
        Task ResetPasswordAsync(ResetPasswordRequest request);
    }
}
