namespace eParking.Model.Requests
{
    public class ReservationUpdateRequest
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public int ParkingSpotId { get; set; }
        public int ReservationTypeId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
