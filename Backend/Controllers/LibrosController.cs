using BibliotecaAPI.Interfaces;
using BibliotecaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BibliotecaAPI.DTOs;

namespace BibliotecaAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LibrosController : ControllerBase
    {
        private readonly ILibroRepository _libroRepository;

        public LibrosController(ILibroRepository libroRepository)
        {
            _libroRepository = libroRepository;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<LibroRespuestaDto>>> GetAll()
        {
            var libros = await _libroRepository.GetAllAsync();
            
            var respuesta = libros.Select(libro => new LibroRespuestaDto
            {
                Id = libro.Id,
                Titulo = libro.Titulo,
                Isbn = libro.Isbn,
                AnioPublicacion = libro.AnioPublicacion,
                Stock = libro.Stock,
                AutorId = libro.AutorId,
                NombreAutor = libro.Autor != null
                    ? $"{libro.Autor.Nombre} {libro.Autor.Apellido}"
                    : string.Empty,
                RutaPortada = libro.RutaPortada,
                RutaPdf = libro.RutaPdf,
                RutaAudio = libro.RutaAudio
            }).ToList();
            return Ok(respuesta);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<LibroRespuestaDto>> GetById(int id)
        {
            var libro = await _libroRepository.GetByIdAsync(id);

            if (libro == null)
            {
                return NotFound();
            }

            var respuesta = new LibroRespuestaDto
            {
                Id = libro.Id,
                Titulo = libro.Titulo,
                Isbn = libro.Isbn,
                AnioPublicacion = libro.AnioPublicacion,
                Stock = libro.Stock,
                AutorId = libro.AutorId,
                NombreAutor = libro.Autor !=null
                    ? $"{libro.Autor.Nombre} {libro.Autor.Apellido}"
                    : string.Empty,
                RutaPortada = libro.RutaPortada,
                RutaPdf = libro.RutaPdf,
                RutaAudio = libro.RutaAudio
            };
            return Ok(respuesta);
        }

        // Solo el administrador puede crear, editar o eliminar libros
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<LibroRespuestaDto>> Create(CrearLibroDto dto)
        {
            if (await _libroRepository.ExisteIsbnAsync(dto.Isbn))
            {
                return Conflict(new
                {
                    message = "El ISBN ya existe en la base de datos."
                });
            }

            if (!await _libroRepository.ExisteAutorAsync(dto.AutorId))
            {
                return BadRequest(new
                {
                    message = "El autor no existe."
                });
            }


            Libro libro = new Libro
            {
                Titulo = dto.Titulo,
                Isbn = dto.Isbn,
                AnioPublicacion = dto.AnioPublicacion,
                Stock = dto.Stock,
                AutorId = dto.AutorId
            };

            var createdLibro = await _libroRepository.CreateAsync(libro);

            // Se vuelve a consultar para traer el Autor (Include) y poder armar NombreAutor
            var libroConAutor = await _libroRepository.GetByIdAsync(createdLibro.Id);

            var respuesta = new LibroRespuestaDto
            {
                Id = createdLibro.Id,
                Titulo = createdLibro.Titulo,
                Isbn = createdLibro.Isbn,
                AnioPublicacion = createdLibro.AnioPublicacion,
                Stock = createdLibro.Stock,
                AutorId = createdLibro.AutorId,
                NombreAutor = libroConAutor?.Autor != null
                    ? $"{libroConAutor.Autor.Nombre} {libroConAutor.Autor.Apellido}"
                    : string.Empty,
                RutaPortada = createdLibro.RutaPortada,
                RutaPdf = createdLibro.RutaPdf,
                RutaAudio = createdLibro.RutaAudio
            };

            return CreatedAtAction(
                nameof(GetById),
                new { id = createdLibro.Id },
                respuesta
            );
        }

        [Authorize(Roles = "Administrador")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ActualizarLibroDto dto)
        {
            var LibroExistente = await _libroRepository.GetByIdAsync(id);

            if (LibroExistente == null)
            {
                return NotFound(new
                {
                    message = "El libro no existe."
                });
            }

            if (await _libroRepository.ExisteIsbnEnOtroLibroAsync(dto.Isbn, id))
            {
                return Conflict(new
                {
                    message = "El ISBN ya existe en otro libro."
                });
            }

            if (!await _libroRepository.ExisteAutorAsync(dto.AutorId))
            {
                return BadRequest(new
                {
                    message = "El autor no existe."
                });
            }

            var libro = new Libro
            {
                Titulo = dto.Titulo,
                Isbn = dto.Isbn,
                AnioPublicacion = dto.AnioPublicacion,
                Stock = dto.Stock,
                AutorId = dto.AutorId
            };

            var actualizado = await _libroRepository.UpdateAsync(id, libro);

            if (!actualizado)
            {
                return NotFound("El libro no existe.");
            }

            return NoContent();
        }

        [Authorize(Roles = "Administrador")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _libroRepository.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
    }
}