namespace eParking.Services
{
    public interface IReservationCompletionService
    {
        Task ProcessExpiredAsync(CancellationToken cancellationToken = default);
    }
}
