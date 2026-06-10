using eParking.Model;
using eParking.Model.Requests;
using eParking.Model.Responses;
using eParking.Model.SearchObjects;
using eParking.Services.Database;
using eParking.Services.Database.Parking;
using Microsoft.EntityFrameworkCore;

namespace eParking.Services
{
    public interface IReservationTypeService : IBaseCRUDService<ReservationTypeResponse, ReservationTypeSearch, ReservationTypeInsertRequest, ReservationTypeUpdateRequest> { }

    public class ReservationTypeService : IReservationTypeService
    {
        private readonly ParkingDbContext _context;

        public ReservationTypeService(ParkingDbContext context) => _context = context;

        public async Task<PagedResponse<ReservationTypeResponse>> GetAllAsync(ReservationTypeSearch? search = null)
        {
            var query = _context.ReservationTypes.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(t => t.Name.Contains(search.Name));
            return await query.OrderBy(t => t.Id).Select(t => Map(t)).ToPagedAsync(search);
        }

        public async Task<ReservationTypeResponse> GetByIdAsync(int id)
        {
            var entity = await _context.ReservationTypes.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException($"ReservationType with id {id} not found.");
            return Map(entity);
        }

        public async Task<ReservationTypeResponse> InsertAsync(ReservationTypeInsertRequest request)
        {
            ValidateBillingUnit(request.BillingUnit);
            var entity = new ReservationType
            {
                Name = request.Name.Trim(),
                Price = request.Price,
                BillingUnit = request.BillingUnit,
                CreatedAt = DateTime.UtcNow
            };
            _context.ReservationTypes.Add(entity);
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task<ReservationTypeResponse> UpdateAsync(ReservationTypeUpdateRequest request)
        {
            var entity = await _context.ReservationTypes.FindAsync(request.Id)
                ?? throw new NotFoundException($"ReservationType with id {request.Id} not found.");
            ValidateBillingUnit(request.BillingUnit);
            entity.Name = request.Name.Trim();
            entity.Price = request.Price;
            entity.BillingUnit = request.BillingUnit;
            entity.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Map(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.ReservationTypes.Include(t => t.Reservations).FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException($"ReservationType with id {id} not found.");
            if (entity.Reservations.Any())
                throw new BusinessException("Cannot delete a reservation type that is used by reservations.");
            _context.ReservationTypes.Remove(entity);
            await _context.SaveChangesAsync();
        }

        private static void ValidateBillingUnit(BillingUnit billingUnit)
        {
            if (!Enum.IsDefined(typeof(BillingUnit), billingUnit))
                throw new BusinessException("Jedinica obračuna mora biti Hourly ili Daily.");
        }

        private static ReservationTypeResponse Map(ReservationType t) => new()
        {
            Id = t.Id,
            Name = t.Name,
            Price = t.Price,
            BillingUnit = t.BillingUnit,
            CreatedAt = t.CreatedAt,
            UpdatedAt = t.UpdatedAt
        };
    }
}
