using System.ComponentModel.DataAnnotations;

namespace eParking.Model.Requests
{
    public class ReservationUpdateRequest
    {
        [Range(1, int.MaxValue)]
        public int Id { get; set; }

        [Range(1, int.MaxValue)]
        public int CarId { get; set; }

        [Range(1, int.MaxValue)]
        public int ParkingSpotId { get; set; }

        [Range(1, int.MaxValue)]
        public int ReservationTypeId { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }
    }
}
