using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class BrandsController : BaseCRUDController<BrandResponse, BrandSearch, BrandInsertRequest, BrandUpdateRequest, IBrandService>
{
    public BrandsController(IBrandService service) : base(service) { }
}
