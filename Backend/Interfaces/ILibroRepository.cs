using BibliotecaAPI.Models;

namespace BibliotecaAPI.Interfaces
{
    public interface ILibroRepository
    {
        Task<IEnumerable<Libro>> GetAllAsync();
        Task<Libro?> GetByIdAsync(int id);
        Task<Libro> CreateAsync(Libro libro);
        Task<bool> UpdateAsync(int id, Libro libro);
        Task<bool> DeleteAsync(int id);
        Task<bool> ExisteIsbnAsync(string isbn);
        Task<bool> ExisteIsbnEnOtroLibroAsync(string isbn, int id);
        Task<bool> ExisteAutorAsync(int autorId);
        Task<bool> ActualizarArchivosAsync(
            int id,
            string? rutaPortada,
            string? rutaPdf,
            string? rutaAudio
        );
        Task<bool> EliminarArchivoAsync(int id, string tipoArchivo);
    }
}   