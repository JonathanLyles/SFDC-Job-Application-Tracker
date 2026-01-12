# Contributing to Job Application Tracker

Thank you for contributing to the Job Application Tracker! This guide will help you get started with the development workflow.

## 🛠️ Development Setup

### Prerequisites

- Node.js 18.x or 20.x
- Salesforce CLI (sf)
- Git

### Initial Setup

1. Clone the repository

```bash
git clone <repository-url>
cd job-application-tracker
```

2. Install dependencies

```bash
npm install
```

3. Verify setup

```bash
npm run test:unit
npm run lint
```

## 🔄 Development Workflow

### 1. Create a Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Write your code following our coding standards
- Add tests for new functionality
- Update documentation as needed

### 3. Pre-Commit Validation

Our project uses Husky and lint-staged to automatically run checks before commits:

- **Prettier**: Automatically formats code
- **ESLint**: Checks code quality
- **Jest Tests**: Runs related tests for changed LWC files

If any checks fail, the commit will be blocked. Fix the issues and try again.

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: add new feature description"
```

**Commit Message Format:**

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test improvements
- `refactor:` - Code refactoring
- `style:` - Code formatting changes

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Create a pull request using the provided template.

## 🧪 Testing Guidelines

### Running Tests

```bash
# Run all tests
npm run test:unit

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage

# Run tests for CI (used by GitHub Actions)
npm run test:unit:ci
```

### Test Requirements

- All new features must include tests
- Maintain or improve test coverage
- Tests should focus on user behavior, not implementation details
- Use descriptive test names that explain what is being tested

### Lightning Web Component Testing

- Use `@salesforce/sfdx-lwc-jest` testing utilities
- Test user interactions and component behavior
- Mock external dependencies and APIs
- Test error conditions and edge cases

## 📋 Code Quality Standards

### ESLint Rules

```bash
# Check code quality
npm run lint

# Check with CI-level strictness
npm run lint:ci
```

### Prettier Formatting

```bash
# Format code
npm run prettier

# Check formatting
npm run format:check
```

### File Organization

- **Lightning Web Components**: `force-app/main/default/lwc/`
- **Test Files**: `force-app/test/default/classes/`
- **Apex Classes**: `force-app/main/default/classes/`
- **Metadata**: `force-app/main/default/*/`

## 🚀 CI/CD Pipeline

### GitHub Actions

Our CI pipeline runs on every push and pull request:

1. **Test Job** - Runs on Node.js 18.x and 20.x
   - Jest unit tests
   - ESLint code quality checks
   - Prettier formatting verification
   - Test coverage reporting

2. **Code Quality Job**
   - Strict ESLint validation
   - Security vulnerability scanning
   - Dependency updates check

3. **Salesforce Deploy Check**
   - Metadata validation (on pull requests)

### Branch Protection

The `main` branch is protected with the following requirements:

- All CI status checks must pass
- Code review required
- Up-to-date branch required
- No force pushes allowed

## 📱 Salesforce Development

### Metadata Best Practices

- Follow Salesforce naming conventions
- Include metadata files for all components
- Test in scratch orgs when possible
- Document custom object relationships

### LWC Development Guidelines

- Use modern JavaScript (ES6+)
- Follow Lightning Design System patterns
- Implement proper error handling
- Use wire services appropriately
- Test reactive properties and methods

## 🐛 Bug Reports and Feature Requests

### Bug Reports

Include:

- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details
- Screenshots if applicable

### Feature Requests

Include:

- Use case description
- Proposed solution
- Alternative solutions considered
- Implementation complexity estimate

## 🔧 Local Development Tools

### Recommended VS Code Extensions

- Salesforce Extension Pack
- ESLint
- Prettier
- Jest Runner
- GitLens

### Git Hooks (Husky)

Pre-commit hooks automatically run:

- Prettier formatting
- ESLint validation
- Jest tests for changed files

## 📞 Getting Help

- Check existing issues and discussions
- Review documentation and README
- Ask questions in pull request comments
- Follow the code review process

## 🏆 Recognition

Contributors will be acknowledged in release notes and the project README. Thank you for helping improve the Job Application Tracker!

---

**Remember**: All commits must pass the automated test suite. The CI pipeline and pre-commit hooks are your safety net to maintain code quality.
