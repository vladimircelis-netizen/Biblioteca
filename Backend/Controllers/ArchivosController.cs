
using BibliotecaAPI.Services;
using BibliotecaAPI.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BibliotecaAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Administrador")]
public class ArchivosController : ControllerBase
{
    private readonly CloudinaryService _cloudinaryService;
    private readonly ILibroRepository _libroRepository;

    public ArchivosController(
        CloudinaryService cloudinaryService,
        ILibroRepository libroRepository)
    {
        _cloudinaryService = cloudinaryService;
        _libroRepository = libroRepository;
    }

    // 1. Subir una portada a Cloudinary
    [HttpPost("portada")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> SubirPortada(
        [FromForm] IFormFile archivo)
    {
        try
        {
            var url = await _cloudinaryService.SubirPortadaAsync(archivo);

            return Ok(new
            {
                mensaje = "Portada subida correctamente",
                url = url
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch (Exception)
        {
            return StatusCode(500, new
            {
                mensaje = "No se pudo subir la portada."
            });
        }
    }

    // 2. Subir una portada y asociarla a un libro
    [HttpPost("libros/{id}/portada")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> SubirPortadaLibro(
        int id,
        [FromForm] IFormFile archivo)
    {
        // Buscar el libro en MySQL
        var libro = await _libroRepository.GetByIdAsync(id);

        if (libro == null)
        {
            return NotFound(new
            {
                mensaje = "El libro no existe."
            });
        }

        try
        {
            // Subir la imagen a Cloudinary
            var url = await _cloudinaryService.SubirPortadaAsync(archivo);

            // Guardar la URL en MySQL
            var actualizado =
                await _libroRepository.ActualizarArchivosAsync(
                    id,
                    url,
                    null,
                    null
                );

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje = "El libro ya no existe."
                });
            }

            return Ok(new
            {
                mensaje = "Portada asociada correctamente al libro.",
                libroId = id,
                rutaPortada = url
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch (Exception)
        {
            return StatusCode(500, new
            {
                mensaje = "No se pudo asociar la portada al libro."
            });
        }
    }


    // 3. Subir un PDF y asociarlo a un libro
    [HttpPost("libros/{id}/pdf")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> SubirPdfLibro(
        int id,
        [FromForm] IFormFile archivo)
    {
        // Buscar el libro en MySQL
        var libro = await _libroRepository.GetByIdAsync(id);

        if (libro == null)
        {
            return NotFound(new
            {
                mensaje = "El libro no existe."
            });
        }

        try
        {
            // Subir el PDF a Cloudinary
            var url = await _cloudinaryService.SubirPdfAsync(archivo);

            // Guardar la URL en MySQL
            var actualizado =
                await _libroRepository.ActualizarArchivosAsync(
                    id,
                    null,
                    url,
                    null
                );

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje = "El libro ya no existe."
                });
            }

            return Ok(new
            {
                mensaje = "PDF asociado correctamente al libro.",
                libroId = id,
                rutaPdf = url
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch (Exception)
        {
            return StatusCode(500, new
            {
                mensaje = "No se pudo asociar el PDF al libro."
            });
        }
    }



    // 4. Subir un audiolibro MP3 y asociarlo a un libro
    [HttpPost("libros/{id}/audio")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> SubirAudioLibro(
        int id,
        [FromForm] IFormFile archivo)
    {
        // Buscar el libro en MySQL
        var libro = await _libroRepository.GetByIdAsync(id);

        if (libro == null)
        {
            return NotFound(new
            {
                mensaje = "El libro no existe."
            });
        }

        try
        {
            // Subir el MP3 a Cloudinary
            var url = await _cloudinaryService.SubirAudioAsync(archivo);

            // Guardar la URL en MySQL
            var actualizado =
                await _libroRepository.ActualizarArchivosAsync(
                    id,
                    null,
                    null,
                    url
                );

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje = "El libro ya no existe."
                });
            }

            return Ok(new
            {
                mensaje = "Audiolibro asociado correctamente.",
                libroId = id,
                rutaAudio = url
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch (Exception)
        {
            return StatusCode(500, new
            {
                mensaje = "No se pudo asociar el audiolibro."
            });
        }
    }


}
