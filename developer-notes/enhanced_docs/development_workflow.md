# Dify Development Workflow Guide

This document outlines the recommended development workflow for contributing to Dify.

## Development Workflow

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/dify.git
   cd dify
   ```

2. **Set Up Development Environment**
   ```bash
   # Run the automated setup script
   chmod +x dev/scripts/setup.sh
   ./dev/scripts/setup.sh
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Development Loop**
   - Make your changes
   - Write/update tests
   - Run tests locally
   - Commit changes with meaningful messages

5. **Testing**
   ```bash
   # Backend Tests
   cd api
   pytest

   # Frontend Tests
   cd web
   npm run lint
   npm test
   ```

6. **Code Review Checklist**
   - [ ] Tests pass locally
   - [ ] Code follows style guidelines
   - [ ] Documentation is updated
   - [ ] Commit messages are clear
   - [ ] Changes are properly tested
   - [ ] No unnecessary changes

7. **Submit Pull Request**
   - Push your changes to your fork
   - Create a pull request
   - Fill out the PR template completely
   - Link relevant issues

## Development Best Practices

### Code Style
- Follow PEP 8 for Python code
- Use ESLint rules for JavaScript/TypeScript
- Use meaningful variable and function names
- Keep functions small and focused
- Comment complex logic

### Testing
- Write unit tests for new features
- Update existing tests when modifying features
- Aim for high test coverage
- Test edge cases
- Use meaningful test names

### Git Practices
- Keep commits atomic and focused
- Write clear commit messages
- Rebase feature branches on main
- Squash commits before merging

### Documentation
- Update README files when needed
- Document new features
- Include code examples
- Update API documentation
- Add comments for complex logic

## Local Development Tips

### Backend Development
1. Run with hot reload:
   ```bash
   flask run --host 0.0.0.0 --port 5001 --debug
   ```

2. Debug with PyCharm or VSCode:
   - Set up Python interpreter from virtual environment
   - Configure debug configuration
   - Set breakpoints

### Frontend Development
1. Run with hot reload:
   ```bash
   npm run dev
   ```

2. Debug with Browser DevTools:
   - Use React DevTools
   - Use Network tab for API calls
   - Use Console for logging

### Database Development
1. Access PostgreSQL:
   ```bash
   docker exec -it dify-postgres psql -U postgres
   ```

2. Run migrations:
   ```bash
   flask db upgrade
   ```

3. Create new migration:
   ```bash
   flask db migrate -m "description"
   ```

## Troubleshooting

### Common Issues

1. **Docker Services**
   - Check services are running:
     ```bash
     docker-compose ps
     ```
   - View logs:
     ```bash
     docker-compose logs
     ```

2. **Database Issues**
   - Check connection settings in `.env`
   - Verify migrations are up to date
   - Check database logs

3. **Frontend Issues**
   - Clear node_modules and reinstall
   - Check for port conflicts
   - Verify API endpoint configuration

4. **Backend Issues**
   - Check virtual environment is activated
   - Verify all dependencies are installed
   - Check environment variables

## Getting Help

1. Check existing documentation
2. Search GitHub issues
3. Ask in community channels
4. Open a new issue

---

Remember to keep this guide updated as development practices evolve.