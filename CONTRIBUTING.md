# Contributing to Hyperliquid Node Docker

We welcome contributions to help improve this project! This guide will help you get started.

## 🚀 Quick Start for Contributors

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/hyperliquid-docker.git
   cd hyperliquid-docker
   ```

2. **Install Development Tools**
   ```bash
   # Install pre-commit for code quality
   apt install pre-commit  # Ubuntu/Debian
   # OR
   brew install pre-commit  # macOS

   # Set up pre-commit hooks
   pre-commit install
   ```

3. **Test Your Setup**
   ```bash
   # Copy and customize environment
   cp default.env .env

   # Test basic functionality
   ./hld up -d
   ./hld logs
   ./hld down
   ```

## 📝 Contribution Guidelines

### Code Standards

- **Shell Scripts**: Follow [shellcheck](https://www.shellcheck.net/) recommendations
- **YAML Files**: Use 2-space indentation, validate syntax
- **Markdown**: Follow [markdownlint](https://github.com/DavidAnson/markdownlint) rules
- **Documentation**: Update README.md for user-facing changes

### Git Workflow

This repository uses a **squash-and-merge workflow** to maintain a clean history:

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Write clear, focused commits
   - Include tests if applicable
   - Update documentation

3. **Test Before Submitting**
   ```bash
   # Run linting
   pre-commit run --all-files

   # Test functionality
   ./hld update
   ./hld up -d --remove-orphans
   ./hld logs
   ```

4. **Submit Pull Request**
   - Use descriptive title and description
   - Reference any related issues
   - Ensure CI checks pass

### Working from main Branch

If you accidentally work on `main`, create an `upstream` remote and clean up:

```bash
# Add upstream remote
git remote add upstream https://github.com/CryptoManufaktur-io/hyperliquid-docker.git

# Create git alias for clean pushes
git config --global alias.push-clean '!git fetch upstream main && git rebase upstream/main && git push -f'

# Use the alias
git push-clean
```

## 🧪 Testing

### Local Testing

**Basic Functionality Tests:**
```bash
# Test different configurations
CHAIN=Testnet NODE_TYPE=non-validator ./hld up -d
./scripts/check_sync.sh
./hld down

# Test tools
docker compose --profile tools run --rm cli hl-visor --help
docker compose --profile tools run --rm validator-info
```

**Documentation Tests:**
```bash
# Check markdown syntax
markdownlint README.md CONTRIBUTING.md

# Test code examples in README
# (manually verify commands work as documented)
```

### CI/CD Testing

The repository includes automated testing via GitHub Actions:
- **Linting**: pre-commit hooks on all files
- **Update Testing**: Verify update mechanism works
- **Documentation**: Check for broken links and formatting

## 🎯 Types of Contributions

### Documentation Improvements
- Fix typos or unclear instructions
- Add examples and use cases
- Improve troubleshooting guides
- Translate documentation

### Feature Enhancements
- New Docker Compose configurations
- Additional utility scripts
- Monitoring improvements
- Security enhancements

### Bug Fixes
- Fix script errors or edge cases
- Resolve Docker configuration issues
- Improve error handling
- Fix documentation inaccuracies

### Infrastructure Improvements
- CI/CD pipeline enhancements
- Testing framework improvements
- Development tooling
- Code quality improvements

## 📋 Pull Request Checklist

Before submitting your PR, ensure:

- [ ] **Code Quality**
  - [ ] Pre-commit hooks pass (`pre-commit run --all-files`)
  - [ ] Code follows project conventions
  - [ ] No hardcoded secrets or sensitive data

- [ ] **Testing**
  - [ ] Local testing completed
  - [ ] Documentation examples verified
  - [ ] No breaking changes (or clearly documented)

- [ ] **Documentation**
  - [ ] README.md updated if needed
  - [ ] Inline code comments added for complex logic
  - [ ] CHANGELOG.md updated for significant changes

- [ ] **Git Hygiene**
  - [ ] Commits are focused and well-described
  - [ ] Branch is up-to-date with main
  - [ ] No merge commits (rebase preferred)

## 🐛 Reporting Issues

### Bug Reports

Please include:
- **Environment**: OS, Docker version, compose version
- **Configuration**: Relevant `.env` settings (redact sensitive data)
- **Steps to Reproduce**: Clear, numbered steps
- **Expected vs Actual**: What you expected and what happened
- **Logs**: Relevant error messages or logs

### Feature Requests

Please include:
- **Use Case**: Why this feature would be valuable
- **Proposed Solution**: How you envision it working
- **Alternatives**: Other solutions you've considered
- **Examples**: Similar implementations in other projects

## 🔧 Development Tips

### Debugging Docker Compose

```bash
# Check service status
docker compose ps

# View resource usage
docker compose top

# Inspect networks
docker network ls
docker network inspect hyperliquid-docker_default

# Check volumes
docker volume ls
docker volume inspect hyperliquid-docker_consensus-data
```

### Shell Script Development

```bash
# Use shellcheck for validation
shellcheck ethd hld scripts/*.sh

# Test with different shells
bash -n script.sh  # Syntax check
```

### YAML Validation

```bash
# Validate compose files
docker compose config

# Check specific compose file
docker compose -f hyperliquid.yml config
```

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and community discussion
- **Discord/Telegram**: Check the main Hyperliquid community channels

## 📄 License

All contributed code will be covered by the [Apache License v2.0](LICENSE) of this project. By contributing, you agree to license your contributions under the same license.
