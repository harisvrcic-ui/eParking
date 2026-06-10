using eParking.Model;
using eParking.Model.Exceptions;

namespace eParking.Services
{
    public static class ReservationEditPolicy
    {
        public static void EnsureCanEdit(ReservationStatus status, bool isAdmin)
        {
            if (status is ReservationStatus.Cancelled or ReservationStatus.Completed)
                throw new BusinessException($"Cannot modify a reservation in '{status}' status.");

            if (!isAdmin && status != ReservationStatus.Pending)
                throw new BusinessException("Only pending reservations can be modified.");
        }

        public static bool ShouldRevertConfirmedToPending(ReservationStatus status, bool isAdmin)
            => isAdmin && status == ReservationStatus.Confirmed;
    }
}
