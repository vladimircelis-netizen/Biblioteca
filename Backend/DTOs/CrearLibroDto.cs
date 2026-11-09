using System.ComponentModel.DataAnnotations;

namespace BibliotecaAPI.DTOs
{
    public class CrearLibroDto
    {
        [Required(ErrorMessage = "El título es obligatorio")]
        [StringLength(200, ErrorMessage = "El título no puede tener más de 200 caracteres")]
        public string Titulo { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "El ISBN es obligatorio")]
        [RegularExpression(@"^(\d{10}|\d{13})$", ErrorMessage = "El ISBN debe tener 10 o 13 digitos")]
        public string Isbn { get; set; } = string.Empty;
        
        [Range(1450,2026, ErrorMessage = "El año de publicación debe estar entre 1450 y 2026")]
        public int AnioPublicacion { get; set; }
        
        [Range(0, int.MaxValue, ErrorMessage = "El stock no puede ser negativo")]
        public int Stock { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Debe ser un autor válido")]
        public int AutorId { get; set; }
    }
}