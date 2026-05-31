using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _service;
    private readonly ICurrentUserService _currentUser;

    public ReviewsController(IReviewService service, ICurrentUserService currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<PagedResponse<ReviewResponse>> GetAll([FromQuery] ReviewSearch? search)
        => await _service.GetAllAsync(search);

    [HttpGet("{id}")]
    public async Task<ActionResult<ReviewResponse>> GetById(int id)
        => Ok(await _service.GetByIdAsync(id));

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<ReviewResponse>> Create([FromBody] ReviewInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPost("my")]
    public async Task<ActionResult<ReviewResponse>> CreateMy([FromBody] ReviewMyUpsertRequest request)
    {
        var result = await _service.InsertAsync(new ReviewInsertRequest
        {
            UserId = _currentUser.GetUserId(),
            ParkingLotId = request.ParkingLotId,
            Rating = request.Rating,
            Comment = request.Comment
        });
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<ReviewResponse>> Update(int id, [FromBody] ReviewUpdateRequest request)
    {
        request.Id = id;
        return Ok(await _service.UpdateAsync(request));
    }

    [HttpPut("my/{id}")]
    public async Task<ActionResult<ReviewResponse>> UpdateMy(int id, [FromBody] ReviewMyUpsertRequest request)
    {
        var existing = await _service.GetByIdAsync(id);
        if (existing.UserId != _currentUser.GetUserId())
            throw new ForbiddenException("You can only edit your own reviews.");

        return Ok(await _service.UpdateAsync(new ReviewUpdateRequest
        {
            Id = id,
            UserId = existing.UserId,
            ParkingLotId = request.ParkingLotId,
            Rating = request.Rating,
            Comment = request.Comment
        }));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
