@echo off
echo ========================================
echo Servicio CODSP Integracion - Cristian Bonelo
echo Team: observabilidad | Project: onboarding-qas
echo Puerto: 8080
echo ========================================
echo.

cd /d "%~dp0"

echo Instalando dependencias...
pip install -r requirements.txt

echo.
echo Iniciando servicio...
echo Metrics: http://localhost:8080/metrics
echo Health: http://localhost:8080/health
echo.

python main.py

pause