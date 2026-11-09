namespace BibliotecaAPI.DTOs
{
    public class ActualizarLibroDto
    {
        public string Titulo { get; set; } = string.Empty;
        public string Isbn { get; set; } = string.Empty;
        public int AnioPublicacion { get; set; }
        public int Stock { get; set; }
        public int AutorId { get; set; }
    }
}