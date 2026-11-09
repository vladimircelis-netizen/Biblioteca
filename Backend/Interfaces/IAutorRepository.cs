using BibliotecaAPI.Models;

namespace BibliotecaAPI.Interfaces
{
    public interface IAutorRepository
    {
        Task<IEnumerable<Autor>> GetAllAsync();
        Task<Autor?> GetByIdAsync(int id);
        Task<Autor> CreateAsync(Autor autor);
        Task<bool> UpdateAsync(int Id, Autor autor);
        Task<bool> DeleteAsync(int Id);
    }
}