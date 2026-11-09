
namespace BibliotecaAPI.Models
{
    public class Libro
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Isbn { get; set; } = string.Empty;
        public int AnioPublicacion { get; set; }
        public int Stock { get; set; }

        // Archivos digitales
        public string? RutaPortada { get; set; }
        public string? RutaPdf { get; set; }
        public string? RutaAudio { get; set; }

        public int AutorId { get; set; }
        public Autor Autor { get; set; } = null!;

        public ICollection<Prestamo> Prestamos { get; set; }
            = new List<Prestamo>();
    }
}
