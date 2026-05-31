namespace eParking.Services
{
    public interface ICurrentUserService
    {
        int GetUserId();
        bool IsInRole(string role);
        bool IsAdmin { get; }
    }
}
