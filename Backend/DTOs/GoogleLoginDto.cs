
using System.ComponentModel.DataAnnotations;

namespace BibliotecaAPI.DTOs;

public class GoogleLoginDto
{
    // Token de identidad (ID token) que entrega Google
    // a la aplicación móvil después de iniciar sesión.
    [Required]
    public string IdToken { get; set; } = string.Empty;
}
