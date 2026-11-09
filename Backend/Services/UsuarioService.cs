
using BibliotecaAPI.DTOs;
using BibliotecaAPI.Interfaces;
using BibliotecaAPI.Models;
using Microsoft.AspNetCore.Identity;

namespace BibliotecaAPI.Services;

public class UsuarioService
{
    private readonly IUsuarioRepository _repository;
    private readonly PasswordHasher<Usuario> _passwordHasher = new();

    public UsuarioService(IUsuarioRepository repository)
    {
        _repository = repository;
    }

    public async Task<Usuario> RegistrarAsync(CrearUsuarioDto dto)
    {
        string email = dto.Email.Trim().ToLowerInvariant();

        // Comprobar si el correo ya existe
        var existente = await _repository.ObtenerPorEmailAsync(email);

        if (existente != null)
        {
            throw new InvalidOperationException(
                "El correo electrónico ya está registrado");
        }

        // Crear el usuario
        var usuario = new Usuario
        {
            Nombre = dto.Nombre.Trim(),
            Apellido = dto.Apellido.Trim(),
            Email = email,
            Telefono = dto.Telefono.Trim(),
            Rol = "Lector",
            FechaRegistro = DateTime.UtcNow
        };

        // Generar el hash de la contraseña
        usuario.PasswordHash =
            _passwordHasher.HashPassword(usuario, dto.Password);

        // Guardar en MySQL
        return await _repository.CrearAsync(usuario);
    }


    public async Task<Usuario?> LoginAsync(LoginUsuarioDto dto)
    {
        // Buscar el usuario por su correo
        string email = dto.Email.Trim().ToLowerInvariant();

        var usuario = await _repository.ObtenerPorEmailAsync(email);

        // Si el usuario no existe
        if (usuario == null)
        {
            return null;
        }

        // Verificar la contraseña
        var resultado = _passwordHasher.VerifyHashedPassword(
            usuario,
            usuario.PasswordHash,
            dto.Password
        );

        // Si la contraseña es incorrecta
        if (resultado == PasswordVerificationResult.Failed)
        {
            return null;
        }

        // Credenciales correctas
        return usuario;
    }

}
