using eParking.Model;

namespace eParking.Model.Requests
{
    public class ReservationTypeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public BillingUnit BillingUnit { get; set; } = BillingUnit.Hourly;
    }
}
