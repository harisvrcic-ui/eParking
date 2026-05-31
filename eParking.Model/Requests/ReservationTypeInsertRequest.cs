namespace eParking.Model.Requests
{
    public class ReservationTypeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
    }
}
