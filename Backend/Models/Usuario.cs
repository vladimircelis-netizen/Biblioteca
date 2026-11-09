namespace BibliotecaAPI.Models
{
    public class Usuario
    {
        public int Id {get; set;}
        public string Nombre {get; set;} = string.Empty;
        public string Apellido {get; set;} = string.Empty;
        public string Email {get; set;} = string.Empty;
        public string Telefono {get; set;} = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Rol { get; set; } = "Lector";
        public DateTime FechaRegistro {get; set;} = DateTime.UtcNow;
        public ICollection<Prestamo> Prestamos {get; set;} = new List<Prestamo>();
    }
}