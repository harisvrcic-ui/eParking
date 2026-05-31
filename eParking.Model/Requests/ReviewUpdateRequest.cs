namespace eParking.Model.Requests
{
    public class ReviewUpdateRequest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ParkingLotId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}

