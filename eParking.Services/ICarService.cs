using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface ICarService : IBaseCRUDService<CarResponse, CarSearch, CarInsertRequest, CarUpdateRequest>
    {
    }
}
