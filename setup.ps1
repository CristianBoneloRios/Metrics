# setup.ps1 - Script de instalación y configuración para CODSP Integración
# Autor: Cristian Bonelo
# Proyecto: onboarding-qas
# Team: observabilidad

param(
    [ValidateSet("install", "run", "reinstall", "help")]
    [string]$Action = "help"
)

# Variables globales
$Script:ServiceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:PythonVersion = "3.11"
$Script:RequirementsFile = Join-Path $Script:ServiceDir "service\requirements.txt"
$Script:MainScript = Join-Path $Script:ServiceDir "service\main.py"

# Colores
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

# Funciones de logging
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "======================================" -ForegroundColor $InfoColor
    Write-Host $Message -ForegroundColor $InfoColor
    Write-Host "======================================" -ForegroundColor $InfoColor
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor $SuccessColor
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ErrorColor
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $WarningColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $InfoColor
}

# Verificar si Python está instalado
function Test-Python {
    Write-Info "Verificando Python..."
    
    $pythonExe = $null
    
    # Intentar con 'py'
    $pyResult = py --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pythonExe = "py"
        Write-Success "Python encontrado: $pyResult"
        return $true
    }
    
    # Intentar con 'python'
    $pythonResult = python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pythonExe = "python"
        Write-Success "Python encontrado: $pythonResult"
        return $true
    }
    
    Write-Error-Custom "Python no está instalado o no está en el PATH"
    return $false
}

# Instalar Python (Windows)
function Install-Python {
    Write-Warning-Custom "Python no se encontró. Intentando instalar..."
    
    Write-Info "Instalando Python $Script:PythonVersion desde Microsoft Store..."
    
    try {
        # Intentar instalar desde Microsoft Store
        Start-Process "ms-windows-store://pdp/?productid=9NRWMJP3717K" -Wait
        
        Write-Info "Por favor, completa la instalación desde Microsoft Store"
        Write-Info "Presiona Enter cuando hayas terminado..."
        Read-Host
        
        # Verificar si la instalación fue exitosa
        if (Test-Python) {
            Write-Success "Python instalado correctamente"
            return $true
        }
        else {
            Write-Error-Custom "La instalación de Python no se completó correctamente"
            return $false
        }
    }
    catch {
        Write-Error-Custom "No se pudo instalar Python: $_"
        return $false
    }
}

# Instalar dependencias
function Install-Dependencies {
    Write-Header "Instalando Dependencias"
    
    if (-not (Test-Path $Script:RequirementsFile)) {
        Write-Error-Custom "Archivo requirements.txt no encontrado en: $Script:RequirementsFile"
        return $false
    }
    
    Write-Info "Ubicación del archivo: $Script:RequirementsFile"
    Write-Info "Ejecutando: py -m pip install -r requirements.txt"
    Write-Host ""
    
    py -m pip install -r $Script:RequirementsFile --trusted-host pypi.org --trusted-host files.pythonhosted.org
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Falló la instalación de dependencias"
        return $false
    }
    
    Write-Success "Dependencias instaladas correctamente"
    return $true
}

# Ejecutar servicio
function Start-Service {
    Write-Header "Iniciando Servicio CODSP Integración"
    
    if (-not (Test-Path $Script:MainScript)) {
        Write-Error-Custom "Archivo main.py no encontrado en: $Script:MainScript"
        return $false
    }
    
    Write-Info "Ubicación del servicio: $Script:MainScript"
    Write-Info "Owner: Cristian Bonelo"
    Write-Info "Team: observabilidad"
    Write-Info "Project: onboarding-qas"
    Write-Info "Entorno: QAS"
    Write-Host ""
    
    Write-Info "Endpoints disponibles:"
    Write-Host "  - Raíz: http://localhost:8080/" -ForegroundColor White
    Write-Host "  - Health: http://localhost:8080/health" -ForegroundColor White
    Write-Host "  - Métricas: http://localhost:8080/metrics" -ForegroundColor White
    Write-Host "  - Documentos: POST http://localhost:8080/documents/process" -ForegroundColor White
    Write-Host "  - APIs Externas: GET http://localhost:8080/external/call/{service}/{endpoint}" -ForegroundColor White
    Write-Host "  - Tareas Background: POST http://localhost:8080/background/task" -ForegroundColor White
    Write-Host "  - IA: POST http://localhost:8080/ai/execute" -ForegroundColor White
    Write-Host "  - Batch: POST http://localhost:8080/batch/operations" -ForegroundColor White
    Write-Host ""
    
    Write-Info "Iniciando servicio..."
    Write-Host ""
    
    Set-Location $Script:ServiceDir
    py service\main.py
    
    return $true
}

# Acción: Install
function Invoke-Install {
    Write-Header "INSTALACIÓN - Servicio CODSP Integración"
    Write-Info "Author: Cristian Bonelo | Team: observabilidad"
    Write-Host ""
    
    if (-not (Test-Python)) {
        if (-not (Install-Python)) {
            Write-Error-Custom "No se puede continuar sin Python"
            exit 1
        }
    }
    
    if (-not (Install-Dependencies)) {
        Write-Error-Custom "No se puede continuar sin las dependencias"
        exit 1
    }
    
    Write-Header "Instalación Completada"
    Write-Success "El servicio está listo para ejecutarse"
    Write-Info "Ejecuta: .\setup.ps1 -Action run"
}

# Acción: Run
function Invoke-Run {
    Write-Header "EJECUCIÓN - Servicio CODSP Integración"
    Write-Info "Author: Cristian Bonelo | Team: observabilidad"
    Write-Host ""
    
    if (-not (Test-Python)) {
        Write-Error-Custom "Python es requerido para ejecutar el servicio"
        Write-Info "Ejecuta primero: .\setup.ps1 -Action install"
        exit 1
    }
    
    if (-not (Install-Dependencies)) {
        Write-Error-Custom "Falló la instalación de dependencias"
        exit 1
    }
    
    Start-Service
}

# Acción: Reinstall
function Invoke-Reinstall {
    Write-Header "REINSTALACIÓN - Servicio CODSP Integración"
    Write-Warning-Custom "Esto reinstalará todas las dependencias"
    Write-Host ""
    
    $confirm = Read-Host "Deseas continuar? (S/N)"
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Info "Operación cancelada"
        return
    }
    
    Write-Info "Desinstalando paquetes previos..."
    py -m pip uninstall -r $Script:RequirementsFile -y
    
    Invoke-Install
}

# Acción: Help
function Invoke-Help {
    Write-Header "AYUDA - Servicio CODSP Integración"
    
    Write-Host "USO:" -ForegroundColor $InfoColor
    Write-Host "  .\setup.ps1 -Action [opcion]" -ForegroundColor White
    Write-Host ""
    
    Write-Host "OPCIONES:" -ForegroundColor $InfoColor
    Write-Host "  install   - Instala Python (si es necesario) y las dependencias" -ForegroundColor White
    Write-Host "  run       - Ejecuta el servicio directamente" -ForegroundColor White
    Write-Host "  reinstall - Desinstala y reinstala todas las dependencias" -ForegroundColor White
    Write-Host "  help      - Muestra esta ayuda" -ForegroundColor White
    Write-Host ""
    
    Write-Host "EJEMPLOS:" -ForegroundColor $InfoColor
    Write-Host "  .\setup.ps1 -Action install" -ForegroundColor White
    Write-Host "  .\setup.ps1 -Action run" -ForegroundColor White
    Write-Host "  .\setup.ps1" -ForegroundColor White
    Write-Host ""
    
    Write-Host "INFORMACIÓN DEL SERVICIO:" -ForegroundColor $InfoColor
    Write-Host "  Autor: Cristian Bonelo" -ForegroundColor White
    Write-Host "  Team: observabilidad" -ForegroundColor White
    Write-Host "  Proyecto: onboarding-qas" -ForegroundColor White
    Write-Host "  Entorno: QAS" -ForegroundColor White
    Write-Host "  Puerto: 8080" -ForegroundColor White
    Write-Host ""
}

# Main
function Main {
    switch ($Action.ToLower()) {
        "install" { Invoke-Install }
        "run" { Invoke-Run }
        "reinstall" { Invoke-Reinstall }
        "help" { Invoke-Help }
        default { Invoke-Help }
    }
}

# Ejecutar
Main
