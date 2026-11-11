using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace BibliotecaAPI.Services;

public class CloudinaryService
{
    private readonly Cloudinary _cloudinary;

    public CloudinaryService(IConfiguration configuration)
    {
        var cloudName = configuration["Cloudinary:CloudName"];
        var apiKey = configuration["Cloudinary:ApiKey"];
        var apiSecret = configuration["Cloudinary:ApiSecret"];

        if (string.IsNullOrWhiteSpace(cloudName) ||
            string.IsNullOrWhiteSpace(apiKey) ||
            string.IsNullOrWhiteSpace(apiSecret))
        {
            throw new InvalidOperationException(
                "Faltan las credenciales de Cloudinary.");
        }

        var cuenta = new Account(
            cloudName,
            apiKey,
            apiSecret
        );

        _cloudinary = new Cloudinary(cuenta);
    }


    public async Task<string> SubirPortadaAsync(IFormFile archivo)
    {
        if (archivo == null || archivo.Length == 0)
        {
            throw new ArgumentException("Debe seleccionar una imagen.");
        }

        var tiposPermitidos = new[]
        {
        "image/jpeg",
        "image/png",
        "image/webp"
    };

        if (!tiposPermitidos.Contains(archivo.ContentType.ToLowerInvariant()))
        {
            throw new ArgumentException(
                "Solo se permiten imágenes JPG, PNG o WebP.");
        }

        const long tamañoMaximo = 5 * 1024 * 1024;

        if (archivo.Length > tamañoMaximo)
        {
            throw new ArgumentException(
                "La imagen no puede superar los 5 MB.");
        }

        using var stream = archivo.OpenReadStream();

        var parametros = new ImageUploadParams
        {
            File = new FileDescription(
                archivo.FileName,
                stream
            ),
            Folder = "biblioteca_movil/portadas"
        };

        var resultado = await _cloudinary.UploadAsync(parametros);

        if (resultado.Error != null)
        {
            throw new Exception(resultado.Error.Message);
        }

        if (resultado.SecureUrl == null)
        {
            throw new Exception("Cloudinary no devolvió la URL de la imagen.");
        }

        return resultado.SecureUrl.ToString();
    }


    public async Task<string> SubirPdfAsync(IFormFile archivo)
    {
        if (archivo == null || archivo.Length == 0)
        {
            throw new ArgumentException(
                "Debe seleccionar un archivo PDF.");
        }

        // Validar el tipo de archivo
        if (archivo.ContentType != "application/pdf")
        {
            throw new ArgumentException(
                "Solo se permiten archivos PDF.");
        }

        // Tamaño máximo: 10 MB
        const long tamañoMaximo = 10 * 1024 * 1024;

        if (archivo.Length > tamañoMaximo)
        {
            throw new ArgumentException(
                "El archivo PDF no puede superar los 10 MB.");
        }

        using var stream = archivo.OpenReadStream();

        var parametros = new ImageUploadParams
        {
            File = new FileDescription(archivo.FileName, stream),
            Folder = "biblioteca_movil/pdf"
        };

        var resultado = await _cloudinary.UploadAsync(parametros);

        if (resultado.Error != null)
        {
            throw new Exception(resultado.Error.Message);
        }

        if (resultado.SecureUrl == null)
        {
            throw new Exception(
                "Cloudinary no devolvió la URL del PDF.");
        }

        return resultado.SecureUrl.ToString();
    }



    public async Task<string> SubirAudioAsync(IFormFile archivo)
    {
        // 1. Verificar que se seleccionó un archivo
        if (archivo == null || archivo.Length == 0)
        {
            throw new ArgumentException(
                "Debe seleccionar un archivo MP3.");
        }

        // 2. Validar el formato
        var tiposPermitidos = new[]
        {
        "audio/mpeg",
        "audio/mp3"
    };

        if (!tiposPermitidos.Contains(
            archivo.ContentType.ToLowerInvariant()))
        {
            throw new ArgumentException(
                "Solo se permiten archivos MP3.");
        }

        // 3. Tamaño máximo: 20 MB para la primera prueba
        const long tamañoMaximo = 20 * 1024 * 1024;

        if (archivo.Length > tamañoMaximo)
        {
            throw new ArgumentException(
                "El archivo MP3 no puede superar los 20 MB.");
        }

        // 4. Abrir el archivo
        using var stream = archivo.OpenReadStream();

        // 5. Preparar la subida a Cloudinary
        var parametros = new VideoUploadParams
        {
            File = new FileDescription(
                archivo.FileName,
                stream
            ),
            Folder = "biblioteca_movil/audiolibros"
        };

        // 6. Subir el MP3
        var resultado = await _cloudinary.UploadAsync(parametros);

        if (resultado.Error != null)
        {
            throw new Exception(resultado.Error.Message);
        }

        // 7. Comprobar que Cloudinary devolvió la URL
        if (resultado.SecureUrl == null)
        {
            throw new Exception(
                "Cloudinary no devolvió la URL del audio.");
        }

        return resultado.SecureUrl.ToString();
    }



    public async Task EliminarArchivoAsync(string? url)
    {
        // Si el libro no tenía archivo, no hay nada que eliminar
        if (string.IsNullOrWhiteSpace(url))
        {
            return;
        }

        // Ejemplo de URL de Cloudinary:
        // https://res.cloudinary.com/demo/image/upload/v1712345/biblioteca_movil/portadas/abc.jpg
        const string marcador = "/upload/";
        var posicion = url.IndexOf(marcador, StringComparison.Ordinal);

        if (posicion < 0)
        {
            return;
        }

        // 1. Tipo de recurso: image (portadas y PDF) o video (audios)
        var tipoRecurso = url.Contains("/video/upload/")
            ? ResourceType.Video
            : ResourceType.Image;

        // 2. Obtener el public_id quitando la versión (v123...) y la extensión
        var publicId = url[(posicion + marcador.Length)..];

        var primeraBarra = publicId.IndexOf('/');

        if (primeraBarra > 1 &&
            publicId[0] == 'v' &&
            publicId[1..primeraBarra].All(char.IsDigit))
        {
            publicId = publicId[(primeraBarra + 1)..];
        }

        var punto = publicId.LastIndexOf('.');

        if (punto > 0)
        {
            publicId = publicId[..punto];
        }

        // 3. Eliminar el archivo de Cloudinary
        var parametros = new DeletionParams(publicId)
        {
            ResourceType = tipoRecurso
        };

        await _cloudinary.DestroyAsync(parametros);
    }

}