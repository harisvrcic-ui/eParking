namespace eParking.Model.Requests
{
    public class ColorInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? HexCode { get; set; }
    }
}
