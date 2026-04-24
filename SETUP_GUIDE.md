# GUÍA DE INSTALACIÓN Y EJECUCIÓN - CODSP Integración

Autor: Cristian Bonelo | Team: observabilidad | Project: onboarding-qas

## Descripción

Este script `setup.ps1` permite instalar y ejecutar el servicio CODSP de manera simple y segura en Windows.

## Requisitos

- Windows 7 o superior
- PowerShell 5.0 o superior
- Acceso a internet (para descargar Python y dependencias)

## Instalación Inicial

Ejecuta el script en tu primera vez:

```powershell
.\setup.ps1 -Action install
```

Este comando:
1. Verifica si Python está instalado
2. Si no está instalado, intenta instalarlo desde Microsoft Store
3. Instala todas las dependencias del proyecto (FastAPI, Prometheus, etc.)
4. Valida que todo esté correctamente configurado

## Ejecutar el Servicio

Una vez instalado, ejecuta:

```powershell
.\setup.ps1 -Action run
```

O simplemente:

```powershell
.\setup.ps1
```

El servicio se iniciará en `http://localhost:8080`

### Endpoints Disponibles

- **Raíz**: `http://localhost:8080/`
- **Health Check**: `http://localhost:8080/health`
- **Métricas Prometheus**: `http://localhost:8080/metrics`
- **Procesar Documentos**: `POST http://localhost:8080/documents/process`
- **Llamar APIs Externas**: `GET http://localhost:8080/external/call/{service}/{endpoint}`
- **Tareas en Background**: `POST http://localhost:8080/background/task`
- **Ejecutar Agentes IA**: `POST http://localhost:8080/ai/execute`
- **Operaciones en Lote**: `POST http://localhost:8080/batch/operations`

## Opciones Avanzadas

### Reinstalar Dependencias

Si necesitas limpiar e reinstalar todas las dependencias:

```powershell
.\setup.ps1 -Action reinstall
```

### Ver Ayuda

Para ver todas las opciones disponibles:

```powershell
.\setup.ps1 -Action help
```

O simplemente:

```powershell
.\setup.ps1
```

## Solución de Problemas

### Python no se instala automáticamente

Si la instalación automática falla:
1. Descarga Python 3.11 desde https://www.python.org/downloads/
2. Ejecuta el instalador
3. Asegúrate de marcar "Add Python to PATH"
4. Vuelve a ejecutar: `.\setup.ps1 -Action install`

### Error: "No se puede cargar el archivo setup.ps1"

PowerShell está bloqueando la ejecución. Ejecuta primero:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Luego intenta de nuevo.

### El servicio no inicia

1. Verifica que Python está en el PATH:
   ```powershell
   py --version
   ```

2. Verifica que las dependencias se instalaron:
   ```powershell
   pip list
   ```

3. Reinstala todo:
   ```powershell
   .\setup.ps1 -Action reinstall
   ```

## Información del Servicio

- **Owner**: Cristian Bonelo
- **Team**: observabilidad
- **Proyecto**: onboarding-qas
- **Entorno**: QAS
- **Puerto**: 8080
- **CODSP QAS IP**: 10.164.10.137
- **Prometheus**: http://10.164.10.137:9090
- **Grafana**: http://10.164.10.137:3000

## Parar el Servicio

Presiona `Ctrl + C` en la terminal donde está ejecutándose el servicio.

## Logs

El servicio muestra logs en tiempo real en la terminal. Los colores indican:
- Verde: Operaciones exitosas
- Rojo: Errores
- Amarillo: Advertencias
- Cyan: Información general
