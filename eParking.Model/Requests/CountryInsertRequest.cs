namespace eParking.Model.Requests
{
    public class CountryInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
    }
}
