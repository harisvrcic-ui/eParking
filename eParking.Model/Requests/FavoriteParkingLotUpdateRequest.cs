namespace eParking.Model.Requests
{
    public class FavoriteParkingLotUpdateRequest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ParkingLotId { get; set; }
    }
}

