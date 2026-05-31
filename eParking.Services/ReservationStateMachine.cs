using eParking.Model.Exceptions;
using eParking.Model;

namespace eParking.Services
{
    /// <summary>
    /// Centralizovana state machine za rezervacije (RS2 tačka 7).
    /// </summary>
    public static class ReservationStateMachine
    {
        private static readonly Dictionary<ReservationStatus, HashSet<ReservationStatus>> AllowedTransitions = new()
        {
            [ReservationStatus.Pending] = [ReservationStatus.Confirmed, ReservationStatus.Cancelled],
            [ReservationStatus.Confirmed] = [ReservationStatus.Cancelled, ReservationStatus.Completed],
            [ReservationStatus.Cancelled] = [],
            [ReservationStatus.Completed] = [],
        };

        public static bool CanTransition(ReservationStatus from, ReservationStatus to)
            => AllowedTransitions.TryGetValue(from, out var targets) && targets.Contains(to);

        public static void EnsureCanTransition(ReservationStatus from, ReservationStatus to)
        {
            if (!CanTransition(from, to))
                throw new BusinessException(
                    $"Status transition from '{from}' to '{to}' is not allowed.");
        }

        /// <summary>Rezervacije u ovim stanjima blokiraju parking mjesto.</summary>
        public static bool BlocksSpot(ReservationStatus status) =>
            status is ReservationStatus.Pending or ReservationStatus.Confirmed;
    }
}
