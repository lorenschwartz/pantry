# Git Integration Guide

## 🚀 Pushing Your Project to GitHub

Follow these steps to push your local work to your GitHub repository at https://github.com/lorenschwartz/pantry.git

### Step 1: Initialize Git (if not already done)

Open Terminal and navigate to your project directory:

```bash
cd /path/to/your/pantry/project
```

If Git isn't initialized yet:

```bash
git init
```

### Step 2: Add Remote Repository

Add your GitHub repository as the remote:

```bash
git remote add origin https://github.com/lorenschwartz/pantry.git
```

To verify:

```bash
git remote -v
```

Should show:
```
origin  https://github.com/lorenschwartz/pantry.git (fetch)
origin  https://github.com/lorenschwartz/pantry.git (push)
```

### Step 3: Create .gitignore

A `.gitignore` file has been created for you with proper Xcode exclusions. It will:
- Ignore user-specific Xcode files
- Ignore build artifacts
- Ignore SwiftData store files
- Ignore macOS system files

### Step 4: Stage All Files

Add all your files to Git:

```bash
git add .
```

Check what will be committed:

```bash
git status
```

### Step 5: Create Initial Commit

Commit all your work:

```bash
git commit -m "Initial commit - Phase 1 complete

Features:
- Complete pantry management system
- Recipe system with cooking mode
- Shopping list functionality
- Insights dashboard with charts
- Smart pantry-recipe integration
- 4,750+ lines of Swift code
- Comprehensive documentation"
```

### Step 6: Push to GitHub

If the remote repository is empty:

```bash
git branch -M main
git push -u origin main
```

If the repository already has content, you may need to pull first:

```bash
git pull origin main --allow-unrelated-histories
```

Then push:

```bash
git push origin main
```

### Step 7: Verify on GitHub

1. Go to https://github.com/lorenschwartz/pantry
2. Refresh the page
3. You should see all your files!

---

## 📁 What Gets Pushed

### Code Files ✅
- All Swift source files (Models, Views, Services)
- Xcode project files
- Asset catalogs
- Info.plist and configuration files

### Documentation ✅
- START_HERE.md
- RECIPE_GUIDE.md
- ARCHITECTURE.md
- QUICK_REFERENCE.md
- TESTING_CHECKLIST.md
- PHASE1_STATUS.md
- SUMMARY.md
- PROGRESS.md
- requirements.md
- plan.md
- README_GITHUB.md (rename to README.md)

### What Gets Ignored ❌
- xcuserdata/ (user-specific settings)
- Build artifacts
- DerivedData/
- SwiftData database files
- .DS_Store and system files

---

## 🔧 Common Git Commands

### Check Status
```bash
git status
```

### Add Files
```bash
git add .                    # Add all files
git add filename.swift       # Add specific file
```

### Commit Changes
```bash
git commit -m "Your message here"
```

### Push Changes
```bash
git push origin main
```

### Pull Changes
```bash
git pull origin main
```

### Create a New Branch
```bash
git checkout -b feature/barcode-scanning
```

### Switch Branches
```bash
git checkout main
```

### View Commit History
```bash
git log --oneline
```

---

## 📝 Git Best Practices

### Commit Messages

Use clear, descriptive commit messages:

**Good:**
```
Add barcode scanning feature

- Implement camera-based scanner
- Add VisionKit integration
- Create barcode database service
```

**Bad:**
```
updates
```

### Commit Frequency

Commit often with logical chunks:
- ✅ After completing a feature
- ✅ After fixing a bug
- ✅ Before switching tasks
- ✅ At end of work session

### Branch Strategy

For future development:

**main** - Stable, working code
**develop** - Integration branch
**feature/*** - New features
**bugfix/*** - Bug fixes

Example:
```bash
git checkout -b feature/receipt-scanning
# ... make changes ...
git add .
git commit -m "Implement receipt scanning"
git push origin feature/receipt-scanning
# Create pull request on GitHub
```

---

## 🐛 Troubleshooting

### Issue: "Remote origin already exists"

Solution:
```bash
git remote remove origin
git remote add origin https://github.com/lorenschwartz/pantry.git
```

### Issue: "Failed to push some refs"

Solution - Pull first, then push:
```bash
git pull origin main --rebase
git push origin main
```

### Issue: "Merge conflicts"

1. Open conflicted files in Xcode
2. Resolve conflicts manually
3. Stage resolved files:
   ```bash
   git add .
   ```
4. Continue:
   ```bash
   git rebase --continue
   # or
   git merge --continue
   ```

### Issue: Large files causing push failure

SwiftData database files might be too large. Make sure they're in .gitignore:
```
*.store
*.store-shm
*.store-wal
```

---

## 🔐 Authentication

### Using Personal Access Token

If prompted for password, use a Personal Access Token:

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes: repo (all)
4. Copy token
5. Use token as password when pushing

### Using SSH (Recommended)

1. Generate SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. Add to ssh-agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. Copy public key:
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

4. Add to GitHub → Settings → SSH and GPG keys

5. Change remote URL:
   ```bash
   git remote set-url origin git@github.com:lorenschwartz/pantry.git
   ```

---

## 📦 After First Push

### Update README

Rename the GitHub-specific README:
```bash
mv README_GITHUB.md README.md
git add README.md
git commit -m "Update README for GitHub"
git push origin main
```

### Add Topics

On GitHub repository page:
1. Click "Add topics"
2. Add: `swift`, `swiftui`, `swiftdata`, `ios`, `ipados`, `pantry`, `recipes`, `shopping-list`

### Enable Issues

1. Go to repository Settings
2. Enable Issues
3. Create issue templates if desired

### Add Description

Add repository description:
> A comprehensive iOS pantry management app with recipes, shopping lists, and smart features

### Add Website

If you have a website or documentation site, add it in repository settings

---

## 🎯 Next Steps After Push

1. **Verify everything is there** - Check GitHub
2. **Update README badges** - Add build status, etc.
3. **Create initial release** - Tag v1.0.0-phase1
4. **Share the repo** - Add to your portfolio
5. **Continue development** - Start Phase 2!

---

## 📞 Need Help?

### Git Resources
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Oh Shit, Git!?!](https://ohshitgit.com/)

### Quick Commands Cheat Sheet

```bash
# Status and Info
git status
git log
git diff

# Basic Workflow
git add .
git commit -m "message"
git push

# Branching
git branch
git checkout -b new-branch
git merge branch-name

# Undo
git reset HEAD~1        # Undo last commit (keep changes)
git reset --hard HEAD~1 # Undo last commit (discard changes)
git checkout -- file    # Discard changes to file

# Remote
git remote -v
git fetch origin
git pull origin main
git push origin main
```

---

**Good luck with your Git integration! 🚀**

Once pushed, your code will be safely backed up and ready to share!
