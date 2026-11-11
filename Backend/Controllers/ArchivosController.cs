
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
    private readonly ILogger<ArchivosController> _logger;

    public ArchivosController(
        CloudinaryService cloudinaryService,
        ILibroRepository libroRepository,
        ILogger<ArchivosController> logger)
    {
        _cloudinaryService = cloudinaryService;
        _libroRepository = libroRepository;
        _logger = logger;
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
    //    (si el libro ya tenía portada, se reemplaza)
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

        // Guardar la portada anterior para eliminarla después
        var rutaAnterior = libro.RutaPortada;

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

            // Eliminar la portada anterior de Cloudinary
            await EliminarDeCloudinaryAsync(rutaAnterior);

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
    //    (si el libro ya tenía PDF, se reemplaza)
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

        // Guardar el PDF anterior para eliminarlo después
        var rutaAnterior = libro.RutaPdf;

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

            // Eliminar el PDF anterior de Cloudinary
            await EliminarDeCloudinaryAsync(rutaAnterior);

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
    //    (si el libro ya tenía audio, se reemplaza)
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

        // Guardar el audio anterior para eliminarlo después
        var rutaAnterior = libro.RutaAudio;

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

            // Eliminar el audio anterior de Cloudinary
            await EliminarDeCloudinaryAsync(rutaAnterior);

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


    // 5. Eliminar la portada de un libro
    [HttpDelete("libros/{id}/portada")]
    public async Task<IActionResult> EliminarPortadaLibro(int id)
    {
        return await EliminarArchivoLibroAsync(id, "portada");
    }

    // 6. Eliminar el PDF de un libro
    [HttpDelete("libros/{id}/pdf")]
    public async Task<IActionResult> EliminarPdfLibro(int id)
    {
        return await EliminarArchivoLibroAsync(id, "pdf");
    }

    // 7. Eliminar el audiolibro de un libro
    [HttpDelete("libros/{id}/audio")]
    public async Task<IActionResult> EliminarAudioLibro(int id)
    {
        return await EliminarArchivoLibroAsync(id, "audio");
    }


    // Quita la ruta del archivo en MySQL y lo elimina de Cloudinary
    private async Task<IActionResult> EliminarArchivoLibroAsync(
        int id,
        string tipoArchivo)
    {
        var libro = await _libroRepository.GetByIdAsync(id);

        if (libro == null)
        {
            return NotFound(new
            {
                mensaje = "El libro no existe."
            });
        }

        var rutaActual = tipoArchivo switch
        {
            "portada" => libro.RutaPortada,
            "pdf" => libro.RutaPdf,
            _ => libro.RutaAudio
        };

        if (string.IsNullOrWhiteSpace(rutaActual))
        {
            return NotFound(new
            {
                mensaje = "El libro no tiene este archivo."
            });
        }

        // 1. Quitar la ruta en MySQL
        var eliminado =
            await _libroRepository.EliminarArchivoAsync(id, tipoArchivo);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje = "El libro ya no existe."
            });
        }

        // 2. Eliminar el archivo de Cloudinary
        await EliminarDeCloudinaryAsync(rutaActual);

        return NoContent();
    }


    // Si Cloudinary falla, solo se registra el error:
    // el libro ya quedó actualizado en MySQL.
    private async Task EliminarDeCloudinaryAsync(string? url)
    {
        try
        {
            await _cloudinaryService.EliminarArchivoAsync(url);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "No se pudo eliminar el archivo de Cloudinary: {Url}",
                url);
        }
    }

}
