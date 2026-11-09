using BibliotecaAPI.Interfaces;
using BibliotecaAPI.Models;
using Microsoft.EntityFrameworkCore;
using BibliotecaAPI.Data;

namespace BibliotecaAPI.Repositories
{
    public class AutorRepository : IAutorRepository
    {
        private readonly AppDbContext _context;

        public AutorRepository(AppDbContext context)
        {
            _context = context;
        }
        public async Task<Autor> CreateAsync(Autor autor)
        {
            await _context.Autores.AddAsync(autor);
            await _context.SaveChangesAsync();
            return autor;
        }

        public async Task<bool> DeleteAsync(int Id)
        {
            var autor = await _context.Autores
                .FirstOrDefaultAsync(a=>a.Id == Id);
            
            if ( autor == null)
            {
                return false;
            }

            _context.Autores.Remove(autor);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<IEnumerable<Autor>> GetAllAsync()
        {
            return await _context.Autores.ToListAsync();
        }

        public async Task<Autor?> GetByIdAsync(int id)
        {
            return await _context.Autores.FirstOrDefaultAsync(a => a.Id == id);
        }

        public async Task<bool> UpdateAsync(int Id, Autor autor)
        {
            var autorExistente = await _context.Autores
                .FirstOrDefaultAsync(a=> a.Id==Id);

            if (autorExistente==null)
            {
                return false;
            }

            autorExistente.Nombre = autor.Nombre;
            autorExistente.Apellido = autor.Apellido;
            autorExistente.Nacionalidad = autor.Nacionalidad;

            await _context.SaveChangesAsync();
            return true;
        }
    }
}