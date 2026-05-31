namespace eParking.Model
{
    /// <summary>
    /// Values aligned with <c>ParkingLotStatus</c> enum in the database layer.
    /// </summary>
    public static class ParkingLotStatusIds
    {
        public const int Active = 1;
        public const int Inactive = 2;
        public const int Maintenance = 3;
        public const int Full = 4;
    }
}
