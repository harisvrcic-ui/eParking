namespace eParking.Model.Responses
{
    public class FavoriteParkingLotResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

