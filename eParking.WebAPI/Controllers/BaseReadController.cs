using eParking.Model.Responses;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eParking.Services;

namespace eParking.WebAPI.Controllers;

[Authorize]
[ApiController]
[Route("[controller]")]
public abstract class BaseReadController<TResponse, TSearch, TService> : ControllerBase
    where TSearch : class
    where TService : IBaseReadService<TResponse, TSearch>
{
    protected readonly TService _service;

    protected BaseReadController(TService service)
    {
        _service = service;
    }

    [HttpGet]
    public virtual async Task<PagedResponse<TResponse>> GetAll([FromQuery] TSearch? search)
        => await _service.GetAllAsync(search);

    [HttpGet("{id}")]
    public virtual async Task<ActionResult<TResponse>> GetById(int id)
        => Ok(await _service.GetByIdAsync(id));
}
