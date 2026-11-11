# Imagen para publicar BibliotecaAPI en Render (o cualquier servidor con Docker)

# 1. Compilar la API
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS compilacion
WORKDIR /src

COPY BibliotecaAPI.csproj .
RUN dotnet restore BibliotecaAPI.csproj

COPY . .
RUN dotnet publish BibliotecaAPI.csproj -c Release -o /app --no-restore

# 2. Imagen final (solo el runtime, más liviana)
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=compilacion /app .

ENV ASPNETCORE_ENVIRONMENT=Production

# Render indica el puerto en la variable PORT (por defecto 10000)
CMD ASPNETCORE_URLS=http://+:${PORT:-8080} dotnet BibliotecaAPI.dll
