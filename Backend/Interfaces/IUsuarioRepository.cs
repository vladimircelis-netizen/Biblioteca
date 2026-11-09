
using BibliotecaAPI.Models;

namespace BibliotecaAPI.Interfaces;

public interface IUsuarioRepository
{
    Task<Usuario?> ObtenerPorEmailAsync(string email);

    Task<Usuario> CrearAsync(Usuario usuario);
    // Actualizar un usuario existente
    Task ActualizarAsync(Usuario usuario);
}
