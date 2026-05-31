namespace eParking.Model.Requests
{
    /// <summary>
    /// Mobile user review — UserId is taken from JWT, not from the client.
    /// </summary>
    public class ReviewMyUpsertRequest
    {
        public int ParkingLotId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
