using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eParking.Services;

namespace eParking.WebAPI.Controllers;

[Authorize]
[ApiController]
[Route("[controller]")]
public abstract class BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>
    : BaseReadController<TResponse, TSearch, TService>
    where TSearch : class
    where TService : IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
{
    protected BaseCRUDController(TService service) : base(service)
    {
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public virtual async Task<ActionResult<TResponse>> Create([FromBody] TInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        var idValue = result?.GetType().GetProperty("Id")?.GetValue(result);
        return CreatedAtAction(nameof(GetById), new { id = idValue }, result);
    }

    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public virtual async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdateRequest request)
    {
        var idProperty = typeof(TUpdateRequest).GetProperty("Id");
        if (idProperty?.CanWrite == true)
            idProperty.SetValue(request, id);

        return Ok(await _service.UpdateAsync(request));
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public virtual async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
