
using BibliotecaAPI.DTOs;
using BibliotecaAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace BibliotecaAPI.Controllers;

[ApiController]
[Route("api/usuarios")]
public class UsuariosController : ControllerBase
{

    private readonly UsuarioService _service;
    private readonly JwtService _jwtService;

    public UsuariosController(
        UsuarioService service,
        JwtService jwtService)
    {
        _service = service;
        _jwtService = jwtService;
    }


    [HttpPost("registro")]
    public async Task<IActionResult> Registrar(
        [FromBody] CrearUsuarioDto dto)
    {
        try
        {
            var usuario = await _service.RegistrarAsync(dto);

            return Created(
                $"/api/usuarios/{usuario.Id}",
                new
                {
                    usuario.Id,
                    usuario.Nombre,
                    usuario.Apellido,
                    usuario.Email,
                    usuario.Rol
                });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new
            {
                mensaje = ex.Message
            });
        }
    }



    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginUsuarioDto dto)
    {
        var usuario = await _service.LoginAsync(dto);

        if (usuario == null)
        {
            return Unauthorized(new
            {
                mensaje = "Correo o contraseña incorrectos"
            });
        }

        // Generar el token JWT
        string token = _jwtService.GenerarToken(usuario);

        return Ok(new
        {
            mensaje = "Inicio de sesión exitoso",
            token = token,
            usuario = new
            {
                usuario.Id,
                usuario.Nombre,
                usuario.Apellido,
                usuario.Email,
                usuario.Rol
            }
        });
    }


    // Registro e inicio de sesión con Google
    [HttpPost("google")]
    public async Task<IActionResult> LoginConGoogle(
        [FromBody] GoogleLoginDto dto)
    {
        try
        {
            var usuario = await _service.LoginConGoogleAsync(dto);

            // Generar el token JWT de nuestra API
            string token = _jwtService.GenerarToken(usuario);

            return Ok(new
            {
                mensaje = "Inicio de sesión con Google exitoso",
                token = token,
                usuario = new
                {
                    usuario.Id,
                    usuario.Nombre,
                    usuario.Apellido,
                    usuario.Email,
                    usuario.Rol
                }
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new
            {
                mensaje = ex.Message
            });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(500, new
            {
                mensaje = ex.Message
            });
        }
    }


    [Authorize]
    [HttpGet("perfil")]
    public IActionResult ObtenerPerfil()
    {
        return Ok(new
        {
            mensaje = "Acceso autorizado",
            nombre = User.Identity?.Name,
            rol = User.FindFirst(
                System.Security.Claims.ClaimTypes.Role
            )?.Value
        });
    }


    [Authorize(Roles = "Administrador")]
    [HttpGet("administracion")]
    public IActionResult Administracion()
    {
        return Ok(new
        {
            mensaje = "Bienvenido al panel de administración"
        });
    }




}
