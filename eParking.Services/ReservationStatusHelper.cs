using eParking.Model;
using eParking.Model.Exceptions;

namespace eParking.Services
{
    public static class ReservationStatusHelper
    {
        public const string UnknownStatusName = "Unknown";

        public static bool IsValid(int status)
            => Enum.IsDefined(typeof(ReservationStatus), status);

        public static ReservationStatus ParseOrThrow(int status)
        {
            if (!IsValid(status))
                throw new BusinessException($"Reservation has invalid status value '{status}'.");

            return (ReservationStatus)status;
        }

        public static string FormatStatus(int status)
            => IsValid(status) ? ((ReservationStatus)status).ToString() : UnknownStatusName;
    }
}
