using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Model.Messaging;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using eParking.Services.Messaging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eParking.Services
{
    public class ReservationService : IReservationService
    {
        private readonly ParkingDbContext _context;
        private readonly INotificationQueuePublisher _notificationPublisher;
        private readonly ILogger<ReservationService> _logger;

        public ReservationService(
            ParkingDbContext context,
            INotificationQueuePublisher notificationPublisher,
            ILogger<ReservationService> logger)
        {
            _context = context;
            _notificationPublisher = notificationPublisher;
            _logger = logger;
        }

        public async Task<PagedResponse<ReservationResponse>> GetAllAsync(ReservationSearch? search = null)
        {
            var query = BuildQuery();
            query = ApplyFilters(query, search);
            return await query
                .OrderByDescending(r => r.Id)
                .Select(r => new ReservationResponse
                {
                    Id = r.Id,
                    CarId = r.CarId,
                    LicensePlate = r.Car != null ? r.Car.LicensePlate : string.Empty,
                    CarModel = r.Car != null ? r.Car.Model : string.Empty,
                    UserId = r.Car != null ? r.Car.UserId : 0,
                    UserFullName = r.Car != null && r.Car.User != null
                        ? (r.Car.User.FirstName + " " + r.Car.User.LastName).Trim()
                        : string.Empty,
                    ParkingSpotId = r.ParkingSpotId,
                    ParkingSpotDisplayName = r.ParkingSpot != null
                        ? (r.ParkingSpot.DisplayName ?? r.ParkingSpot.ParkingNumber.ToString())
                        : string.Empty,
                    ParkingLotId = r.ParkingSpot != null && r.ParkingSpot.Zone != null
                        ? r.ParkingSpot.Zone.ParkingLotId
                        : 0,
                    ParkingLotName = r.ParkingSpot != null && r.ParkingSpot.Zone != null && r.ParkingSpot.Zone.ParkingLot != null
                        ? r.ParkingSpot.Zone.ParkingLot.Name
                        : string.Empty,
                    ReservationTypeId = r.ReservationTypeId,
                    ReservationTypeName = r.ReservationType != null ? r.ReservationType.Name : string.Empty,
                    StartDate = r.StartDate,
                    EndDate = r.EndDate,
                    FinalPrice = r.FinalPrice,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt,
                    Status = r.Status == (int)ReservationStatus.Pending ? nameof(ReservationStatus.Pending)
                        : r.Status == (int)ReservationStatus.Confirmed ? nameof(ReservationStatus.Confirmed)
                        : r.Status == (int)ReservationStatus.Cancelled ? nameof(ReservationStatus.Cancelled)
                        : r.Status == (int)ReservationStatus.Completed ? nameof(ReservationStatus.Completed)
                        : ReservationStatusHelper.UnknownStatusName,
                    StatusChangedAt = r.StatusChangedAt,
                    StatusChangedByUserId = r.StatusChangedByUserId,
                    StatusChangedByFullName = r.StatusChangedByUser != null
                        ? (r.StatusChangedByUser.FirstName + " " + r.StatusChangedByUser.LastName).Trim()
                        : null,
                    StatusNote = r.StatusNote
                })
                .ToPagedAsync(search);
        }

        public async Task<ReservationResponse> GetByIdAsync(int id)
        {
            var item = await BuildQuery().FirstOrDefaultAsync(r => r.Id == id);
            if (item == null)
                throw new NotFoundException($"Reservation with id {id} not found.");

            return MapToResponse(item);
        }

        public async Task<ReservationResponse> InsertAsync(ReservationInsertRequest request)
        {
            var (car, spot, reservationType) = await LoadAndValidateReservationResourcesAsync(
                request.CarId, request.ParkingSpotId, request.ReservationTypeId);

            var (startUtc, endUtc) = ReservationTimeHelper.NormalizeAndValidatePeriod(
                request.StartDate, request.EndDate);

            await EnsureSpotAvailableAsync(request.ParkingSpotId, startUtc, endUtc);
            await EnsureNoDuplicateUserReservationAsync(car.UserId, startUtc, endUtc);

            var finalPrice = ReservationPricing.Calculate(reservationType, spot, startUtc, endUtc);

            var entity = new Reservation
            {
                CarId = request.CarId,
                ParkingSpotId = request.ParkingSpotId,
                ReservationTypeId = request.ReservationTypeId,
                StartDate = startUtc,
                EndDate = endUtc,
                FinalPrice = finalPrice,
                CreatedAt = DateTime.UtcNow,
                Status = (int)ReservationStatus.Pending,
                StatusChangedAt = DateTime.UtcNow,
                StatusChangedByUserId = car.UserId,
                StatusNote = "Rezervacija kreirana, ceka potvrdu administratora."
            };

            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(r => r.Id == entity.Id);
            await PublishNotificationAsync(entity, "Rezervacija poslana",
                $"Vasa rezervacija #{entity.Id} na lokaciji {GetLotName(entity)} ceka potvrdu administratora.");
            return MapToResponse(entity);
        }

        public Task<ReservationResponse> UpdateAsync(ReservationUpdateRequest request)
            => UpdateAsync(request, actorUserId: 0, isAdmin: false);

        public async Task<ReservationResponse> UpdateAsync(
            ReservationUpdateRequest request,
            int actorUserId,
            bool isAdmin)
        {
            var entity = await _context.Reservations
                .Include(r => r.Car)
                .FirstOrDefaultAsync(r => r.Id == request.Id)
                ?? throw new NotFoundException($"Reservation with id {request.Id} not found.");

            var currentStatus = ReservationStatusHelper.ParseOrThrow(entity.Status);
            ReservationEditPolicy.EnsureCanEdit(currentStatus, isAdmin);
            var revertToPending = ReservationEditPolicy.ShouldRevertConfirmedToPending(currentStatus, isAdmin);

            var (car, spot, reservationType) = await LoadAndValidateReservationResourcesAsync(
                request.CarId, request.ParkingSpotId, request.ReservationTypeId);

            var (startUtc, endUtc) = ReservationTimeHelper.NormalizeAndValidatePeriod(
                request.StartDate, request.EndDate);

            await EnsureSpotAvailableAsync(request.ParkingSpotId, startUtc, endUtc, request.Id);
            await EnsureNoDuplicateUserReservationAsync(car.UserId, startUtc, endUtc, request.Id);

            entity.CarId = request.CarId;
            entity.ParkingSpotId = request.ParkingSpotId;
            entity.ReservationTypeId = request.ReservationTypeId;
            entity.StartDate = startUtc;
            entity.EndDate = endUtc;
            entity.FinalPrice = ReservationPricing.Calculate(reservationType, spot, startUtc, endUtc);
            entity.UpdatedAt = DateTime.UtcNow;

            if (revertToPending)
            {
                entity.Status = (int)ReservationStatus.Pending;
                entity.StatusChangedAt = DateTime.UtcNow;
                entity.StatusChangedByUserId = actorUserId > 0 ? actorUserId : null;
                entity.StatusNote = "Izmijenjeno od strane administratora, ponovo ceka potvrdu.";
            }

            await _context.SaveChangesAsync();
            entity = await BuildQuery().FirstAsync(r => r.Id == entity.Id);

            if (revertToPending)
            {
                await PublishNotificationAsync(entity, "Rezervacija izmijenjena",
                    $"Vasa rezervacija #{entity.Id} na lokaciji {GetLotName(entity)} je izmijenjena od strane administratora i ponovo ceka potvrdu.");
            }

            return MapToResponse(entity);
        }

        public Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest request, int actorUserId, bool isAdmin)
        {
            var reason = StringNormalization.TrimOrEmpty(request.Reason);
            if (reason.Length == 0)
                throw new BusinessException("Cancellation reason is required.");

            return ChangeStatusAsync(id, ReservationStatus.Cancelled, actorUserId, reason,
                isAdmin, isReject: false);
        }

        public async Task<ReservationResponse> ConfirmAsync(int id, ReservationConfirmRequest? request, int actorUserId)
        {
            request ??= new ReservationConfirmRequest();
            var entity = await _context.Reservations
                .Include(r => r.Car).ThenInclude(c => c.User)
                .Include(r => r.ParkingSpot).ThenInclude(s => s.Zone).ThenInclude(z => z.ParkingLot)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Reservation with id {id} not found.");

            if (ReservationStatusHelper.ParseOrThrow(entity.Status) != ReservationStatus.Pending)
                throw new BusinessException("Only pending reservations can be confirmed.");

            await EnsureSpotAvailableAsync(entity.ParkingSpotId, entity.StartDate, entity.EndDate, id);
            await EnsureNoDuplicateUserReservationAsync(entity.Car.UserId, entity.StartDate, entity.EndDate, id);

            var note = string.IsNullOrWhiteSpace(request.Note)
                ? "Potvrdeno od strane administratora."
                : $"Potvrdeno: {request.Note.Trim()}";

            ApplyStatusTransition(entity, ReservationStatus.Confirmed, actorUserId, note);
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(r => r.Id == entity.Id);
            await PublishNotificationAsync(entity, "Rezervacija potvrdena",
                $"Vasa rezervacija #{entity.Id} na lokaciji {GetLotName(entity)} je potvrdena.");
            return MapToResponse(entity);
        }

        public Task<ReservationResponse> RejectAsync(int id, ReservationRejectRequest request, int actorUserId)
        {
            var reason = StringNormalization.TrimOrEmpty(request.Reason);
            if (reason.Length == 0)
                throw new BusinessException("Rejection reason is required.");

            return ChangeStatusAsync(id, ReservationStatus.Cancelled, actorUserId, reason,
                isAdmin: true, isReject: true);
        }

        public Task DeleteAsync(int id)
        {
            throw new BusinessException(
                "Hard delete is not allowed. Use POST /Reservations/{id}/cancel or /reject to change status.");
        }

        private async Task<ReservationResponse> ChangeStatusAsync(
            int id,
            ReservationStatus targetStatus,
            int actorUserId,
            string? note,
            bool isAdmin,
            bool isReject)
        {
            var entity = await _context.Reservations
                .Include(r => r.Car).ThenInclude(c => c.User)
                .Include(r => r.ParkingSpot).ThenInclude(s => s.Zone).ThenInclude(z => z.ParkingLot)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new NotFoundException($"Reservation with id {id} not found.");

            var current = ReservationStatusHelper.ParseOrThrow(entity.Status);

            if (isReject)
            {
                if (current != ReservationStatus.Pending)
                    throw new BusinessException("Only pending reservations can be rejected.");
            }
            else
            {
                if (current != ReservationStatus.Confirmed && current != ReservationStatus.Pending)
                    throw new BusinessException("Only pending or confirmed reservations can be cancelled.");

                if (!isAdmin && current == ReservationStatus.Confirmed &&
                    ReservationTimeHelper.ToUtcForCompare(entity.StartDate) <= ReservationTimeHelper.UtcNow)
                    throw new BusinessException("Cannot cancel a reservation that has already started.");
            }

            var description = isReject
                ? $"Odbijeno: {note}"
                : $"Otkazano: {note}";

            ApplyStatusTransition(entity, targetStatus, actorUserId, description);
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            entity = await BuildQuery().FirstAsync(r => r.Id == entity.Id);

            var title = isReject ? "Rezervacija odbijena" : "Rezervacija otkazana";
            var body = isReject
                ? $"Vasa rezervacija #{entity.Id} je odbijena. Razlog: {note}"
                : $"Vasa rezervacija #{entity.Id} je otkazana. Razlog: {note}";

            await PublishNotificationAsync(entity, title, body);
            return MapToResponse(entity);
        }

        private static void ApplyStatusTransition(
            Reservation entity,
            ReservationStatus targetStatus,
            int? actorUserId,
            string note)
        {
            var current = ReservationStatusHelper.ParseOrThrow(entity.Status);
            ReservationStateMachine.EnsureCanTransition(current, targetStatus);

            entity.Status = (int)targetStatus;
            entity.StatusChangedAt = DateTime.UtcNow;
            entity.StatusChangedByUserId = actorUserId;
            entity.StatusNote = note?.Trim();
        }

        private async Task<(Car Car, ParkingSpot Spot, ReservationType ReservationType)> LoadAndValidateReservationResourcesAsync(
            int carId,
            int parkingSpotId,
            int reservationTypeId)
        {
            var car = await _context.Cars.FindAsync(carId)
                ?? throw new NotFoundException($"Car with id {carId} not found.");

            if (!car.IsActive)
                throw new BusinessException("Car is not active.");

            var spot = await _context.ParkingSpots
                .Include(s => s.ParkingSpotType)
                .Include(s => s.Zone).ThenInclude(z => z.ParkingLot)
                .FirstOrDefaultAsync(s => s.Id == parkingSpotId)
                ?? throw new NotFoundException($"ParkingSpot with id {parkingSpotId} not found.");

            if (!spot.IsActive)
                throw new BusinessException("Parking spot is not available.");

            if (spot.Zone == null)
                throw new BusinessException("Parking spot is not linked to an active zone.");

            if (!spot.Zone.IsActive)
                throw new BusinessException("Parking zone is not active.");

            if (spot.Zone.ParkingLot == null)
                throw new BusinessException("Parking zone is not linked to an active parking lot.");

            if (!spot.Zone.ParkingLot.IsActive)
                throw new BusinessException("Parking lot is not active.");

            var reservationType = await _context.ReservationTypes.FindAsync(reservationTypeId)
                ?? throw new NotFoundException($"ReservationType with id {reservationTypeId} not found.");

            return (car, spot, reservationType);
        }

        public static async Task EnsureSpotAvailableAsync(
            ParkingDbContext context,
            int parkingSpotId,
            DateTime startDate,
            DateTime endDate,
            int? excludeReservationId = null)
        {
            var startUtc = ReservationTimeHelper.NormalizeToUtc(startDate);
            var endUtc = ReservationTimeHelper.NormalizeToUtc(endDate);
            ReservationTimeHelper.ValidateReservationPeriod(startUtc, endUtc);

            var blockingStatuses = new[] { (int)ReservationStatus.Pending, (int)ReservationStatus.Confirmed };

            var overlap = await context.Reservations.AnyAsync(r =>
                r.ParkingSpotId == parkingSpotId &&
                blockingStatuses.Contains(r.Status) &&
                r.StartDate < endUtc &&
                r.EndDate > startUtc &&
                (!excludeReservationId.HasValue || r.Id != excludeReservationId.Value));

            if (overlap)
                throw new BusinessException("Parking spot is already reserved for the selected period.");
        }

        private async Task EnsureSpotAvailableAsync(int parkingSpotId, DateTime startDate, DateTime endDate, int? excludeReservationId = null)
        {
            await EnsureSpotAvailableAsync(_context, parkingSpotId, startDate, endDate, excludeReservationId);
        }

        private async Task EnsureNoDuplicateUserReservationAsync(int userId, DateTime startUtc, DateTime endUtc, int? excludeId = null)
        {
            var blockingStatuses = new[] { (int)ReservationStatus.Pending, (int)ReservationStatus.Confirmed };

            var duplicate = await _context.Reservations.AnyAsync(r =>
                r.Car.UserId == userId &&
                blockingStatuses.Contains(r.Status) &&
                r.StartDate < endUtc &&
                r.EndDate > startUtc &&
                (!excludeId.HasValue || r.Id != excludeId.Value));

            if (duplicate)
                throw new BusinessException("You already have an active reservation for the selected period.");
        }

        private IQueryable<Reservation> BuildQuery()
        {
            return _context.Reservations
                .AsNoTracking()
                .Include(r => r.Car).ThenInclude(c => c.User)
                .Include(r => r.ParkingSpot).ThenInclude(s => s.Zone).ThenInclude(z => z.ParkingLot)
                .Include(r => r.ReservationType)
                .Include(r => r.StatusChangedByUser);
        }

        private static IQueryable<Reservation> ApplyFilters(IQueryable<Reservation> query, ReservationSearch? search)
        {
            if (search == null) return query;

            if (search.UserId.HasValue)
                query = query.Where(r => r.Car.UserId == search.UserId.Value);

            if (search.CarId.HasValue)
                query = query.Where(r => r.CarId == search.CarId.Value);

            if (search.ParkingSpotId.HasValue)
                query = query.Where(r => r.ParkingSpotId == search.ParkingSpotId.Value);

            if (search.ParkingLotId.HasValue)
                query = query.Where(r => r.ParkingSpot.Zone.ParkingLotId == search.ParkingLotId.Value);

            if (search.FromDate.HasValue)
                query = query.Where(r => r.EndDate >= search.FromDate.Value);

            if (search.ToDate.HasValue)
                query = query.Where(r => r.StartDate <= search.ToDate.Value);

            if (search.Status.HasValue)
                query = query.Where(r => r.Status == (int)search.Status.Value);

            return query;
        }

        private async Task PublishNotificationAsync(Reservation reservation, string title, string body)
        {
            var userId = reservation.Car?.UserId ?? 0;
            if (userId == 0)
                return;

            var message = new NotificationDispatchMessage
            {
                UserId = userId,
                ReservationId = reservation.Id,
                Title = title,
                Body = body
            };

            try
            {
                await _notificationPublisher.PublishNotificationAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Failed to publish reservation notification. reservationId={ReservationId} userId={UserId}",
                    reservation.Id, userId);
            }
        }

        private static string GetLotName(Reservation reservation)
            => reservation.ParkingSpot?.Zone?.ParkingLot?.Name ?? "parking";

        private static ReservationResponse MapToResponse(Reservation reservation)
        {
            var status = ReservationStatusHelper.ParseOrThrow(reservation.Status);
            return new ReservationResponse
            {
                Id = reservation.Id,
                CarId = reservation.CarId,
                LicensePlate = reservation.Car?.LicensePlate ?? string.Empty,
                CarModel = reservation.Car?.Model ?? string.Empty,
                UserId = reservation.Car?.UserId ?? 0,
                UserFullName = $"{reservation.Car?.User?.FirstName} {reservation.Car?.User?.LastName}".Trim(),
                ParkingSpotId = reservation.ParkingSpotId,
                ParkingSpotDisplayName = reservation.ParkingSpot?.DisplayName ?? reservation.ParkingSpot?.ParkingNumber.ToString() ?? string.Empty,
                ParkingLotId = reservation.ParkingSpot?.Zone?.ParkingLotId ?? 0,
                ParkingLotName = reservation.ParkingSpot?.Zone?.ParkingLot?.Name ?? string.Empty,
                ReservationTypeId = reservation.ReservationTypeId,
                ReservationTypeName = reservation.ReservationType?.Name ?? string.Empty,
                StartDate = reservation.StartDate,
                EndDate = reservation.EndDate,
                FinalPrice = reservation.FinalPrice,
                CreatedAt = reservation.CreatedAt,
                UpdatedAt = reservation.UpdatedAt,
                Status = status.ToString(),
                StatusChangedAt = reservation.StatusChangedAt,
                StatusChangedByUserId = reservation.StatusChangedByUserId,
                StatusChangedByFullName = reservation.StatusChangedByUser != null
                    ? $"{reservation.StatusChangedByUser.FirstName} {reservation.StatusChangedByUser.LastName}".Trim()
                    : null,
                StatusNote = reservation.StatusNote
            };
        }
    }
}
