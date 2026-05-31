using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface IMyAppUserService : IBaseCRUDService<MyAppUserResponse, MyAppUserSearch, MyAppUserInsertRequest, MyAppUserUpdateRequest>
    {
        Task ChangePasswordAsync(int userId, string currentPassword, string newPassword);
        Task<MyAppUserResponse> UpdateProfilePictureAsync(int userId, string? pictureBase64);
    }
}
