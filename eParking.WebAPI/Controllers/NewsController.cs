using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eParking.WebAPI.Controllers;

[Authorize]
public class NewsController
    : BaseCRUDController<NewsResponse, NewsSearch, NewsInsertRequest, NewsUpdateRequest, INewsService>
{
    private readonly ICurrentUserService _currentUser;

    public NewsController(INewsService service, ICurrentUserService currentUser) : base(service)
    {
        _currentUser = currentUser;
    }

    [HttpGet]
    public override async Task<PagedResponse<NewsResponse>> GetAll([FromQuery] NewsSearch? search)
    {
        search ??= new NewsSearch();
        if (!_currentUser.IsAdmin)
            search.IsActive = true;
        return await _service.GetAllAsync(search);
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<NewsResponse>> Create([FromBody] NewsInsertRequest request)
        => base.Create(request);

    [HttpPut("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public override Task<ActionResult<NewsResponse>> Update(int id, [FromBody] NewsUpdateRequest request)
        => base.Update(id, request);

    [HttpDelete("{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
