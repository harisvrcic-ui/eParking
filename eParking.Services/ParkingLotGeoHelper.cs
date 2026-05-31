using eParking.Services.Database.Parking;

namespace eParking.Services
{
    /// <summary>
    /// Resolves parking lot coordinates from DB or known defaults.
    /// </summary>
    internal static class ParkingLotGeoHelper
    {
        private static readonly Dictionary<string, (double Lat, double Lng)> ByName =
            new(StringComparer.OrdinalIgnoreCase)
            {
                ["Vijećnica"] = (43.8590, 18.4335),
                ["Vijecnica"] = (43.8590, 18.4335),
                ["Baščaršija"] = (43.8594, 18.4312),
                ["Bascarsija"] = (43.8594, 18.4312),
                ["Aria Mall"] = (43.8425, 18.3360),
                ["Sarajevo"] = (43.8564, 18.4131),
                ["Sarajevo Centar"] = (43.8586, 18.4280),
                ["Ilidža"] = (43.8280, 18.3100),
                ["Novo Sarajevo"] = (43.8480, 18.3950),
            };

        public static (double? Lat, double? Lng) GetCoordinates(ParkingLot lot)
        {
            if (lot.Latitude.HasValue && lot.Longitude.HasValue)
                return (lot.Latitude, lot.Longitude);

            if (ByName.TryGetValue(lot.Name, out var coords))
                return coords;

            var offset = (lot.Id % 7) * 0.004;
            return (43.8564 + offset, 18.4131 + offset * 0.8);
        }
    }
}
