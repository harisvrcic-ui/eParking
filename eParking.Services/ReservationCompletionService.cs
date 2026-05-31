using eParking.Model;
using eParking.Model.Messaging;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using eParking.Services.Messaging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eParking.Services
{
    /// <summary>
    /// Automatski prelaz Confirmed → Completed nakon isteka termina (RS2 8.2 — BackgroundService).
    /// </summary>
    public class ReservationCompletionService : IReservationCompletionService
    {
        private readonly ParkingDbContext _context;
        private readonly INotificationQueuePublisher _notificationPublisher;
        private readonly ILogger<ReservationCompletionService> _logger;

        public ReservationCompletionService(
            ParkingDbContext context,
            INotificationQueuePublisher notificationPublisher,
            ILogger<ReservationCompletionService> logger)
        {
            _context = context;
            _notificationPublisher = notificationPublisher;
            _logger = logger;
        }

        public async Task ProcessExpiredAsync(CancellationToken cancellationToken = default)
        {
            var now = ReservationTimeHelper.UtcNow;
            var expired = await _context.Reservations
                .Include(r => r.Car)
                .Include(r => r.ParkingSpot).ThenInclude(s => s.Zone).ThenInclude(z => z.ParkingLot)
                .Where(r => r.Status == (int)ReservationStatus.Confirmed && r.EndDate <= now)
                .ToListAsync(cancellationToken);

            if (expired.Count == 0)
                return;

            foreach (var reservation in expired)
            {
                ReservationStateMachine.EnsureCanTransition(ReservationStatus.Confirmed, ReservationStatus.Completed);
                reservation.Status = (int)ReservationStatus.Completed;
                reservation.StatusChangedAt = DateTime.UtcNow;
                reservation.StatusChangedByUserId = null;
                reservation.StatusNote = "Automatski zavrseno nakon isteka termina.";
                reservation.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync(cancellationToken);

            foreach (var reservation in expired)
            {
                await PublishNotificationAsync(reservation, cancellationToken);
            }

            _logger.LogInformation("Auto-completed {Count} expired reservations.", expired.Count);
        }

        private async Task PublishNotificationAsync(Reservation reservation, CancellationToken cancellationToken)
        {
            var userId = reservation.Car?.UserId ?? 0;
            if (userId == 0)
                return;

            var lotName = reservation.ParkingSpot?.Zone?.ParkingLot?.Name ?? "parking";
            var message = new NotificationDispatchMessage
            {
                UserId = userId,
                ReservationId = reservation.Id,
                Title = "Rezervacija zavrsena",
                Body = $"Vasa rezervacija #{reservation.Id} na lokaciji {lotName} je zavrsena."
            };

            try
            {
                await _notificationPublisher.PublishNotificationAsync(message, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Failed to publish completion notification. reservationId={ReservationId}",
                    reservation.Id);
            }
        }
    }
}
