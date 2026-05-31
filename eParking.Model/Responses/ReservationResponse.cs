namespace eParking.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string CarModel { get; set; } = string.Empty;
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public int ParkingSpotId { get; set; }
        public string ParkingSpotDisplayName { get; set; } = string.Empty;
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public int ReservationTypeId { get; set; }
        public string ReservationTypeName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal FinalPrice { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime? StatusChangedAt { get; set; }
        public int? StatusChangedByUserId { get; set; }
        public string? StatusChangedByFullName { get; set; }
        public string? StatusNote { get; set; }
    }
}
