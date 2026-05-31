using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class MyAppUsersController
    : BaseCRUDController<MyAppUserResponse, MyAppUserSearch, MyAppUserInsertRequest, MyAppUserUpdateRequest, IMyAppUserService>
{
    public MyAppUsersController(IMyAppUserService service) : base(service)
    {
    }
}
