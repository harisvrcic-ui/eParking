using eParking.Model;

namespace eParking.Model.Responses
{
    public class ReservationTypeResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public BillingUnit BillingUnit { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
