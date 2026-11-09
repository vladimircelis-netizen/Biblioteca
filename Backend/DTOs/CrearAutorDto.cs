using System.ComponentModel.DataAnnotations;

namespace BibliotecaAPI.DTOs
{
    public class CrearAutorDto
    {
        [Required(ErrorMessage = "El nombre es obligatorio")]
        [StringLength(100, ErrorMessage = "El nombre no puede tener más de 100 caracteres")]
        public string Nombre {get; set;} = string.Empty;

        [Required(ErrorMessage = "El apellido es obligatorio")]
        [StringLength(100, ErrorMessage = "El apellido no puede tener más de 100 caracteres")]
        public string Apellido {get; set;} = string.Empty;

        [Required(ErrorMessage = "La nacionalidad es obligatoria")]
        [StringLength(100, ErrorMessage = "La nacionalidad no puede tener más de 100 caracteres")]
        public string Nacionalidad {get; set;} = string.Empty;
    }
}