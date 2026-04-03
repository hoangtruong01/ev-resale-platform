# EVN Market - Development Setup Script
# This script will set up and run the development environment

Write-Host "🚀 EVN Market Development Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if we're in the correct directory
$currentDir = Get-Location
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ Error: docker-compose.yml not found. Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Write-Host "📁 Current directory: $currentDir" -ForegroundColor Cyan

# Function to check if a port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("127.0.0.1", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Check for required ports
Write-Host "🔍 Checking required ports..." -ForegroundColor Yellow
$requiredPorts = @(3000, 3001, 5432)
$portsInUse = @()

foreach ($port in $requiredPorts) {
    if (Test-Port $port) {
        $portsInUse += $port
        Write-Host "⚠️  Port $port is already in use" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Port $port is available" -ForegroundColor Green
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "❌ Some required ports are in use. Please stop services on these ports or use the following commands:" -ForegroundColor Red
    Write-Host "   Kill processes: Get-Process | Where-Object {`$_.ProcessName -eq 'node'} | Stop-Process -Force" -ForegroundColor Yellow
    Write-Host "   Or use: docker-compose down" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to continue anyway? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        exit 1
    }
}

# Display menu options
Write-Host ""
Write-Host "📋 Choose how to run the project:" -ForegroundColor Cyan
Write-Host "1. Docker Compose (Recommended - All services)" -ForegroundColor White
Write-Host "2. Manual Setup (Backend + Frontend separately)" -ForegroundColor White
Write-Host "3. Database Only (PostgreSQL + pgAdmin)" -ForegroundColor White
Write-Host "4. Check logs of running containers" -ForegroundColor White
Write-Host "5. Stop all services" -ForegroundColor White

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host "🐳 Starting all services with Docker Compose..." -ForegroundColor Green
        Write-Host "This will start: PostgreSQL, pgAdmin, Backend API, Frontend" -ForegroundColor Cyan
        
        # Stop any existing containers first
        docker-compose down
        
        # Build and start all services
        docker-compose up --build
    }
    
    "2" {
        Write-Host "🔧 Manual Setup - Starting Backend and Frontend separately..." -ForegroundColor Green
        
        # Start database only
        Write-Host "📊 Starting PostgreSQL database..." -ForegroundColor Cyan
        docker-compose up -d postgres pgadmin
        
        # Wait a bit for database to be ready
        Write-Host "⏳ Waiting for database to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Start backend in new terminal
        Write-Host "🔗 Starting Backend API..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-Command", "cd '$currentDir\be'; npm install; npm run db:generate; npm run db:migrate; npm run dev"
        
        # Wait a bit for backend to start
        Start-Sleep -Seconds 5
        
        # Start frontend in new terminal
        Write-Host "🎨 Starting Frontend..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-Command", "cd '$currentDir\FE'; npm install; npm run dev"
        
        Write-Host "✅ Services are starting in separate terminals!" -ForegroundColor Green
        Write-Host "🌐 Frontend: http://localhost:3001" -ForegroundColor Cyan
        Write-Host "🔗 Backend API: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "🗄️  pgAdmin: http://localhost:8080" -ForegroundColor Cyan
    }
    
    "3" {
        Write-Host "🗄️  Starting Database services only..." -ForegroundColor Green
        docker-compose up -d postgres pgadmin
        Write-Host "✅ Database services started!" -ForegroundColor Green
        Write-Host "🗄️  pgAdmin: http://localhost:8080 (admin@evnmarket.com / admin123)" -ForegroundColor Cyan
    }
    
    "4" {
        Write-Host "📋 Checking container logs..." -ForegroundColor Green
        docker-compose logs --tail=50
    }
    
    "5" {
        Write-Host "🛑 Stopping all services..." -ForegroundColor Yellow
        docker-compose down
        Write-Host "✅ All services stopped!" -ForegroundColor Green
    }
    
    default {
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 Setup complete!" -ForegroundColor Green
Write-Host "📖 For more information, check SETUP_GUIDE.md" -ForegroundColor Cyan

# Display important URLs
Write-Host ""
Write-Host "🌐 Important URLs:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3001" -ForegroundColor White
Write-Host "   Backend API: http://localhost:3000" -ForegroundColor White
Write-Host "   API Docs: http://localhost:3000/api" -ForegroundColor White
Write-Host "   pgAdmin: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test Registration: http://localhost:3001/register" -ForegroundColor Yellow