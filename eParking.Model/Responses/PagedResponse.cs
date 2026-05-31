namespace eParking.Model.Responses
{
    public class PagedResponse<T>
    {
        public IList<T> Items { get; set; } = new List<T>();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }
}
