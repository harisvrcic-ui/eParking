namespace eParking.Model.Requests
{
    public class CarInsertRequest
    {
        public int BrandId { get; set; }
        public int ColorId { get; set; }
        public int UserId { get; set; }
        public string Model { get; set; } = string.Empty;
        public string LicensePlate { get; set; } = string.Empty;
        public int? YearOfManufacture { get; set; }
        public string? Picture { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
