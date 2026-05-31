namespace eParking.Model.Requests
{
    public class CityInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public int? CountryId { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
