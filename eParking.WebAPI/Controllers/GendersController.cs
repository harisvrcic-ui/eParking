using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class GendersController
    : BaseCRUDController<GenderResponse, GenderSearch, GenderInsertRequest, GenderUpdateRequest, IGenderService>
{
    public GendersController(IGenderService service) : base(service) { }
}
