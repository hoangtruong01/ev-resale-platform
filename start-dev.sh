#!/bin/bash

# EVN Market - Development Setup Script (Bash version)
echo "🚀 EVN Market Development Setup"
echo "================================="

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the project root directory."
    exit 1
fi

echo "📁 Current directory: $(pwd)"

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is in use"
        return 0
    else
        echo "✅ Port $1 is available"
        return 1
    fi
}

# Check required ports
echo "🔍 Checking required ports..."
ports_in_use=()
for port in 3000 3001 5432; do
    if check_port $port; then
        ports_in_use+=($port)
    fi
done

if [ ${#ports_in_use[@]} -gt 0 ]; then
    echo "❌ Some required ports are in use: ${ports_in_use[*]}"
    echo "   Kill processes: sudo lsof -ti:3000,3001,5432 | xargs kill -9"
    echo "   Or use: docker-compose down"
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Display menu
echo ""
echo "📋 Choose how to run the project:"
echo "1. Docker Compose (Recommended - All services)"
echo "2. Manual Setup (Backend + Frontend separately)"
echo "3. Database Only (PostgreSQL + pgAdmin)"
echo "4. Check logs of running containers"
echo "5. Stop all services"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "🐳 Starting all services with Docker Compose..."
        docker-compose down
        docker-compose up --build
        ;;
    2)
        echo "🔧 Manual Setup - Starting services separately..."
        
        # Start database
        echo "📊 Starting PostgreSQL database..."
        docker-compose up -d postgres pgadmin
        
        echo "⏳ Waiting for database to be ready..."
        sleep 10
        
        # Start backend
        echo "🔗 Starting Backend API..."
        gnome-terminal -- bash -c "cd be && npm install && npm run db:generate && npm run db:migrate && npm run dev; exec bash" 2>/dev/null || \
        xterm -e "cd be && npm install && npm run db:generate && npm run db:migrate && npm run dev; bash" 2>/dev/null || \
        echo "Please manually run: cd be && npm install && npm run db:generate && npm run db:migrate && npm run dev"
        
        sleep 5
        
        # Start frontend
        echo "🎨 Starting Frontend..."
        gnome-terminal -- bash -c "cd FE && npm install && npm run dev; exec bash" 2>/dev/null || \
        xterm -e "cd FE && npm install && npm run dev; bash" 2>/dev/null || \
        echo "Please manually run: cd FE && npm install && npm run dev"
        
        echo "✅ Services are starting!"
        ;;
    3)
        echo "🗄️  Starting Database services only..."
        docker-compose up -d postgres pgadmin
        echo "✅ Database services started!"
        ;;
    4)
        echo "📋 Checking container logs..."
        docker-compose logs --tail=50
        ;;
    5)
        echo "🛑 Stopping all services..."
        docker-compose down
        echo "✅ All services stopped!"
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎉 Setup complete!"
echo "📖 For more information, check SETUP_GUIDE.md"
echo ""
echo "🌐 Important URLs:"
echo "   Frontend: http://localhost:3001"
echo "   Backend API: http://localhost:3000"
echo "   API Docs: http://localhost:3000/api"
echo "   pgAdmin: http://localhost:8080"
echo ""
echo "🧪 Test Registration: http://localhost:3001/register"