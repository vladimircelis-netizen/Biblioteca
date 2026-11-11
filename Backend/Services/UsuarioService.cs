
using BibliotecaAPI.DTOs;
using BibliotecaAPI.Interfaces;
using BibliotecaAPI.Models;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Identity;

namespace BibliotecaAPI.Services;

public class UsuarioService
{
    private readonly IUsuarioRepository _repository;
    private readonly IConfiguration _configuration;
    private readonly PasswordHasher<Usuario> _passwordHasher = new();

    public UsuarioService(
        IUsuarioRepository repository,
        IConfiguration configuration)
    {
        _repository = repository;
        _configuration = configuration;
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

        // Las cuentas creadas con Google no tienen contraseña
        if (string.IsNullOrEmpty(usuario.PasswordHash))
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


    // Registrar o iniciar sesión con una cuenta de Google.
    // - Si el correo no existe, se crea un usuario Lector.
    // - Si ya existe, se inicia sesión con esa cuenta.
    public async Task<Usuario> LoginConGoogleAsync(GoogleLoginDto dto)
    {
        // ID de cliente web creado en Google Cloud Console
        var clientId = _configuration["Google:ClientId"];

        if (string.IsNullOrWhiteSpace(clientId))
        {
            throw new InvalidOperationException(
                "No se ha configurado Google:ClientId en el servidor");
        }

        GoogleJsonWebSignature.Payload datosGoogle;

        try
        {
            // 1. Verificar con Google que el token es auténtico,
            // que no ha expirado y que fue emitido para nuestra app
            datosGoogle = await GoogleJsonWebSignature.ValidateAsync(
                dto.IdToken,
                new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new[] { clientId }
                });
        }
        catch (InvalidJwtException)
        {
            throw new UnauthorizedAccessException(
                "El token de Google no es válido");
        }

        if (!datosGoogle.EmailVerified)
        {
            throw new UnauthorizedAccessException(
                "El correo de Google no está verificado");
        }

        string email = datosGoogle.Email.Trim().ToLowerInvariant();

        // 2. Si el usuario ya existe, iniciar sesión
        var existente = await _repository.ObtenerPorEmailAsync(email);

        if (existente != null)
        {
            return existente;
        }

        // 3. Si no existe, registrarlo con los datos de Google.
        // No tiene contraseña: solo puede entrar con Google.
        var usuario = new Usuario
        {
            Nombre = datosGoogle.GivenName ?? datosGoogle.Name ?? email,
            Apellido = datosGoogle.FamilyName ?? string.Empty,
            Email = email,
            Telefono = string.Empty,
            PasswordHash = string.Empty,
            Rol = "Lector",
            FechaRegistro = DateTime.UtcNow
        };

        return await _repository.CrearAsync(usuario);
    }

}
