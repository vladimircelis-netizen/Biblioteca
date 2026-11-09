using BibliotecaAPI.Interfaces;
using Microsoft.AspNetCore.Mvc;
using BibliotecaAPI.DTOs;
using BibliotecaAPI.Models;

namespace BibliotecaAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AutoresController : ControllerBase
    {
        private readonly IAutorRepository _autorRepository;

        public AutoresController(IAutorRepository autorRepository)
        {
            _autorRepository = autorRepository;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<AutorRespuestaDto>>>GetAutores()
        {
            var autores = await _autorRepository.GetAllAsync();

            var respuesta = autores.Select(a=> new AutorRespuestaDto
            {
                Id = a.Id,
                Nombre = a.Nombre,
                Apellido = a.Apellido,
                Nacionalidad = a.Nacionalidad

            });

            return Ok(respuesta);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<AutorRespuestaDto>> GetAutor(int id)
        {
            var autor= await _autorRepository.GetByIdAsync(id);

            if (autor == null)
            {
                return NotFound(new{message = "El autor no existe"});
            }

            var respuesta = new AutorRespuestaDto
            {
                Id = autor.Id,
                Nombre = autor.Nombre,
                Apellido = autor.Apellido,
                Nacionalidad = autor.Nacionalidad
            };

            return Ok(respuesta);
        }

        [HttpPost]
        public async Task<ActionResult<AutorRespuestaDto>> CrearAutor([FromBody] CrearAutorDto dto)
        {
            var autor = new Autor
            {
                Nombre = dto.Nombre,
                Apellido = dto.Apellido,
                Nacionalidad = dto.Nacionalidad
            };

            var nuevoAutor = await _autorRepository.CreateAsync(autor);

            var respuesta = new AutorRespuestaDto
            {
                Id = nuevoAutor.Id,
                Nombre = nuevoAutor.Nombre,
                Apellido = nuevoAutor.Apellido,
                Nacionalidad = nuevoAutor.Nacionalidad
            };

            return CreatedAtAction(nameof(GetAutor), new { id = nuevoAutor.Id }, respuesta);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> ActualizarAutor(
            int id,
            [FromBody] ActualizarAutorDto dto)
        {
            var autor = new Autor
            {
                Nombre = dto.Nombre,
                Apellido = dto.Apellido,
                Nacionalidad = dto.Nacionalidad
            };

            var actualizado = await _autorRepository.UpdateAsync(id, autor);

            if (!actualizado)
            {
                return NotFound(new { message = "El autor no existe" });
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> EliminarAutor(int id)
        {
            var eliminado = await _autorRepository.DeleteAsync(id);

            if (!eliminado)
            {
                return NotFound(new { message = "El autor no existe" });
            }

            return NoContent();
        }
    }

}