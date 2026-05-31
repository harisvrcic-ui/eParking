namespace eParking.Model.Requests
{
    public class CityUpdateRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int? CountryId { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
