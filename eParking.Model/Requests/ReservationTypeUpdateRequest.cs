using eParking.Model;

namespace eParking.Model.Requests
{
    public class ReservationTypeUpdateRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public BillingUnit BillingUnit { get; set; } = BillingUnit.Hourly;
    }
}
