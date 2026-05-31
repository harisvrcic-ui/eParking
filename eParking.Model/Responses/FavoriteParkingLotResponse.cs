namespace eParking.Model.Responses
{
    public class FavoriteParkingLotResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

