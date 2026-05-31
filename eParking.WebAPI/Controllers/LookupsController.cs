using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class LookupsController : ControllerBase
{
    private readonly ILookupService _lookupService;

    public LookupsController(ILookupService lookupService)
    {
        _lookupService = lookupService;
    }

    [HttpGet("genders")]
    public async Task<PagedResponse<LookupItemResponse>> GetGenders([FromQuery] LookupSearch? search)
        => await _lookupService.GetGendersAsync(search);

    [HttpGet("countries")]
    public async Task<PagedResponse<LookupItemResponse>> GetCountries([FromQuery] LookupSearch? search)
        => await _lookupService.GetCountriesAsync(search);

    [HttpGet("cities")]
    public async Task<PagedResponse<LookupItemResponse>> GetCities([FromQuery] LookupSearch? search)
        => await _lookupService.GetCitiesAsync(search);

    [HttpGet("brands")]
    public async Task<PagedResponse<LookupItemResponse>> GetBrands([FromQuery] LookupSearch? search)
        => await _lookupService.GetBrandsAsync(search);

    [HttpGet("colors")]
    public async Task<PagedResponse<LookupItemResponse>> GetColors([FromQuery] LookupSearch? search)
        => await _lookupService.GetColorsAsync(search);

    [HttpGet("parking-spot-types")]
    public async Task<PagedResponse<LookupItemResponse>> GetParkingSpotTypes([FromQuery] LookupSearch? search)
        => await _lookupService.GetParkingSpotTypesAsync(search);

    [HttpGet("reservation-types")]
    public async Task<PagedResponse<LookupItemResponse>> GetReservationTypes([FromQuery] LookupSearch? search)
        => await _lookupService.GetReservationTypesAsync(search);
}
