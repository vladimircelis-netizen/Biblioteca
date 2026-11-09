
using System.ComponentModel.DataAnnotations;

namespace BibliotecaAPI.DTOs;

public class LoginUsuarioDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}
