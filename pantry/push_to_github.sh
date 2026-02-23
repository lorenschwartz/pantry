#!/bin/bash

# Pantry App - Quick Git Push Script
# This script will help you push your project to GitHub

echo "🍳 Pantry App - Git Integration"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    exit 1
fi

print_success "Git is installed"
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    print_status "Initializing Git repository..."
    git init
    print_success "Git repository initialized"
else
    print_success "Git repository already initialized"
fi
echo ""

# Check/add remote
print_status "Checking remote repository..."
if git remote | grep -q origin; then
    current_remote=$(git remote get-url origin)
    echo "   Current remote: $current_remote"
    
    if [ "$current_remote" != "https://github.com/lorenschwartz/pantry.git" ]; then
        print_warning "Remote URL doesn't match. Updating..."
        git remote set-url origin https://github.com/lorenschwartz/pantry.git
        print_success "Remote URL updated"
    else
        print_success "Remote is correctly configured"
    fi
else
    print_status "Adding remote repository..."
    git remote add origin https://github.com/lorenschwartz/pantry.git
    print_success "Remote added"
fi
echo ""

# Rename README if needed
if [ -f "README_GITHUB.md" ]; then
    print_status "Renaming README_GITHUB.md to README.md..."
    mv README_GITHUB.md README.md
    print_success "README renamed"
    echo ""
fi

# Show status
print_status "Checking repository status..."
echo ""
git status
echo ""

# Ask user if they want to continue
read -p "Do you want to stage all files and commit? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Stage all files
    print_status "Staging all files..."
    git add .
    print_success "Files staged"
    echo ""
    
    # Show what will be committed
    print_status "Files to be committed:"
    git status --short
    echo ""
    
    # Create commit
    print_status "Creating commit..."
    git commit -m "Initial commit - Phase 1 complete

Features:
- Complete pantry management system
- Recipe system with cooking mode  
- Shopping list functionality
- Insights dashboard with charts
- Smart pantry-recipe integration
- 4,750+ lines of Swift code
- Comprehensive documentation

Phase 1: Foundation - 95% Complete ✅"
    
    print_success "Commit created"
    echo ""
    
    # Ask about branch
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_status "Current branch: $current_branch"
        read -p "Rename to 'main'? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -M main
            print_success "Branch renamed to 'main'"
        fi
    fi
    echo ""
    
    # Push to GitHub
    read -p "Push to GitHub? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Pushing to GitHub..."
        echo ""
        
        # Try to push
        if git push -u origin main; then
            print_success "Successfully pushed to GitHub!"
            echo ""
            echo "🎉 Your project is now on GitHub!"
            echo "   Visit: https://github.com/lorenschwartz/pantry"
        else
            print_warning "Push failed. This might be because:"
            echo "   1. Remote repository has content (need to pull first)"
            echo "   2. Authentication failed (need Personal Access Token)"
            echo "   3. Network issues"
            echo ""
            echo "Try manually:"
            echo "   git pull origin main --allow-unrelated-histories"
            echo "   git push origin main"
        fi
    fi
else
    echo "Cancelled. Run this script again when ready."
fi

echo ""
print_status "Git integration complete!"
echo ""
echo "📚 For more help, see GIT_INTEGRATION.md"
