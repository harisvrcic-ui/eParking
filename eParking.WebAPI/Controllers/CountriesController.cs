using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[Authorize(Roles = AppRoles.Admin)]
public class CountriesController
    : BaseCRUDController<CountryResponse, CountrySearch, CountryInsertRequest, CountryUpdateRequest, ICountryService>
{
    public CountriesController(ICountryService service) : base(service) { }
}
