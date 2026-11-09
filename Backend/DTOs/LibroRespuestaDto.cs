
namespace BibliotecaAPI.DTOs
{
    public class LibroRespuestaDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Isbn { get; set; } = string.Empty;
        public int AnioPublicacion { get; set; }
        public int Stock { get; set; }
        public int AutorId { get; set; }
        public string NombreAutor { get; set; } = string.Empty;

        // Archivos digitales almacenados en la nube
        public string? RutaPortada { get; set; }
        public string? RutaPdf { get; set; }
        public string? RutaAudio { get; set; }
    }
}
