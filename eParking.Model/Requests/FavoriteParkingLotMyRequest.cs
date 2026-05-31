namespace eParking.Model.Requests
{
    /// <summary>
    /// Mobile user favorite — UserId is taken from JWT, not from the client.
    /// </summary>
    public class FavoriteParkingLotMyRequest
    {
        public int ParkingLotId { get; set; }
    }
}
