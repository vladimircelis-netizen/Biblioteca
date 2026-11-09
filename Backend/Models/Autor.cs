
namespace BibliotecaAPI.Models
{
    public class Autor
    {
        public int Id {get; set;}
        public string Nombre {get; set;} = string.Empty;
        public string Apellido {get; set;} = string.Empty;
        public string Nacionalidad {get; set;} = string.Empty;
        public ICollection<Libro> Libros {get; set;} = new List<Libro>();
    }
}