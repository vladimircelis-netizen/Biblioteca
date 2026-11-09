using BibliotecaAPI.Data;
using BibliotecaAPI.Interfaces;
using BibliotecaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace BibliotecaAPI.Repositories
{
    public class LibroRepository : ILibroRepository
    {
        private readonly AppDbContext _context;

        public LibroRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Libro>> GetAllAsync()
        {
            return await _context.Libros
                .Include(l => l.Autor)
                .ToListAsync();
        }

        public async Task<Libro?> GetByIdAsync(int id)
        {
            return await _context.Libros
                .Include(l => l.Autor)
                .FirstOrDefaultAsync(l => l.Id == id);
}

        public async Task<Libro> CreateAsync(Libro libro)
        {
            await _context.Libros.AddAsync(libro);
            await _context.SaveChangesAsync();
            return libro;
        }

        public async Task<bool> UpdateAsync(int id, Libro libro)
        {
            var existente = await _context.Libros.FindAsync(id);
            
            if (existente == null)
            {
                return false;
            }

            existente.Titulo = libro.Titulo;
            existente.Isbn= libro.Isbn;
            existente.AutorId = libro.AutorId;
            existente.AnioPublicacion = libro.AnioPublicacion;
            existente.Stock = libro.Stock;
            await _context.SaveChangesAsync();
            return true;
        }


        public async Task<bool> ActualizarArchivosAsync(
            int id,
            string? rutaPortada,
            string? rutaPdf,
            string? rutaAudio)
        {
            var libro = await _context.Libros.FindAsync(id);

            if (libro == null)
            {
                return false;
            }

            // Actualizar únicamente las rutas proporcionadas
            if (rutaPortada != null)
            {
                libro.RutaPortada = rutaPortada;
            }

            if (rutaPdf != null)
            {
                libro.RutaPdf = rutaPdf;
            }

            if (rutaAudio != null)
            {
                libro.RutaAudio = rutaAudio;
            }

            await _context.SaveChangesAsync();

            return true;
        }


        public async Task<bool> DeleteAsync(int id)
        {
            var libro = await _context.Libros.FindAsync(id);
            if (libro == null)
            {
                return false;
            }

            _context.Libros.Remove(libro);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> ExisteIsbnAsync(string isbn)
        {
            return await _context.Libros.AnyAsync(l => l.Isbn == isbn);
        }

        public async Task<bool> ExisteIsbnEnOtroLibroAsync(string isbn, int id)
        {
            return await _context.Libros.AnyAsync(l => l.Isbn == isbn && l.Id != id);
        }

        public async Task<bool> ExisteAutorAsync(int autorId)
        {
            return await _context.Autores.AnyAsync(a => a.Id == autorId);
        }
    }
}