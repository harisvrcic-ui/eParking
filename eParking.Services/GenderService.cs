using eParking.Model.Requests;

using eParking.Model.Responses;

using eParking.Model.SearchObjects;

using eParking.Services.Database;

using eParking.Services.Database.Parking;

using Microsoft.EntityFrameworkCore;



namespace eParking.Services

{

    public interface IGenderService : IBaseCRUDService<GenderResponse, GenderSearch, GenderInsertRequest, GenderUpdateRequest> { }



    public class GenderService : IGenderService

    {

        private readonly ParkingDbContext _context;



        public GenderService(ParkingDbContext context) => _context = context;



        public async Task<PagedResponse<GenderResponse>> GetAllAsync(GenderSearch? search = null)

        {

            var query = _context.Genders.AsNoTracking();

            if (!string.IsNullOrWhiteSpace(search?.Name))

                query = query.Where(g => g.Name.Contains(search.Name));

            if (search?.IsActive.HasValue == true)

                query = query.Where(g => g.IsActive == search.IsActive.Value);



            return await query.OrderBy(g => g.Id).Select(g => new GenderResponse
            {
                Id = g.Id,
                Name = g.Name,
                IsActive = g.IsActive,
                CreatedAt = g.CreatedAt,
                UpdatedAt = g.UpdatedAt
            }).ToPagedAsync(search);

        }



        public async Task<GenderResponse> GetByIdAsync(int id)

        {

            var entity = await _context.Genders.AsNoTracking().FirstOrDefaultAsync(g => g.Id == id)

                ?? throw new NotFoundException($"Gender with id {id} not found.");

            return Map(entity);

        }



        public async Task<GenderResponse> InsertAsync(GenderInsertRequest request)

        {

            var name = request.Name.Trim();

            if (string.IsNullOrWhiteSpace(name))

                throw new BusinessException("Name is required.");



            if (await _context.Genders.AnyAsync(g => g.Name == name))

                throw new BusinessException("Gender with this name already exists.");



            var entity = new Gender

            {

                Name = name,

                IsActive = request.IsActive,

                CreatedAt = DateTime.UtcNow

            };

            _context.Genders.Add(entity);

            await _context.SaveChangesAsync();

            return Map(entity);

        }



        public async Task<GenderResponse> UpdateAsync(GenderUpdateRequest request)

        {

            var name = request.Name.Trim();

            if (string.IsNullOrWhiteSpace(name))

                throw new BusinessException("Name is required.");



            var entity = await _context.Genders.FindAsync(request.Id)

                ?? throw new NotFoundException($"Gender with id {request.Id} not found.");



            if (await _context.Genders.AnyAsync(g => g.Name == name && g.Id != request.Id))

                throw new BusinessException("Gender with this name already exists.");



            entity.Name = name;

            entity.IsActive = request.IsActive;

            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Map(entity);

        }



        public async Task DeleteAsync(int id)

        {

            var entity = await _context.Genders.Include(g => g.Users).FirstOrDefaultAsync(g => g.Id == id)

                ?? throw new NotFoundException($"Gender with id {id} not found.");

            if (entity.Users.Any())

                throw new BusinessException("Cannot delete a gender that is used by users.");

            _context.Genders.Remove(entity);

            await _context.SaveChangesAsync();

        }



        private static GenderResponse Map(Gender g) => new()

        {

            Id = g.Id,

            Name = g.Name,

            IsActive = g.IsActive,

            CreatedAt = g.CreatedAt,

            UpdatedAt = g.UpdatedAt

        };

    }

}


