using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;

namespace eParking.Services
{
    public interface IReservationService : IBaseCRUDService<ReservationResponse, ReservationSearch, ReservationInsertRequest, ReservationUpdateRequest>
    {
        Task<ReservationResponse> UpdateAsync(ReservationUpdateRequest request, int actorUserId, bool isAdmin);
        Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest request, int actorUserId, bool isAdmin);
        Task<ReservationResponse> ConfirmAsync(int id, ReservationConfirmRequest? request, int actorUserId);
        Task<ReservationResponse> RejectAsync(int id, ReservationRejectRequest request, int actorUserId);
    }
}
