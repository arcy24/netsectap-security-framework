# Contributing to NetSecTap Security Framework

Thank you for your interest in contributing to the NetSecTap Security Framework! We welcome contributions from the community to make this project better.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Guidelines](#development-guidelines)
- [Reporting Issues](#reporting-issues)
- [Feature Requests](#feature-requests)
- [Pull Request Process](#pull-request-process)

## 📜 Code of Conduct

### Our Standards

We are committed to providing a welcoming and inclusive environment. We expect all contributors to:

- Be respectful and professional
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting, or derogatory remarks
- Publishing others' private information
- Any conduct that would be considered unprofessional

## 🚀 Getting Started

### Prerequisites

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/netsectap-security-framework.git
   cd netsectap-security-framework
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/arcy24/netsectap-security-framework.git
   ```

### Development Setup

```bash
# Make scripts executable
chmod +x run-assessment.sh
chmod +x web/run-assessment.sh
chmod +x network/scripts/*.sh

# Install development dependencies
pip3 install pylint flake8 pytest

# Run tests (when available)
# pytest tests/
```

## 🤝 How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Bug Fixes** - Fix issues in existing functionality
2. **New Features** - Add new assessment modules or capabilities
3. **Documentation** - Improve README, guides, or code comments
4. **Testing** - Add or improve test coverage
5. **Performance** - Optimize existing code
6. **UI/UX** - Improve command-line interface or output formatting

### Areas We'd Love Help With

- 🔍 **Additional Security Checks**
  - More OWASP Top 10 coverage
  - API security testing
  - Cloud security assessments (AWS, Azure, GCP)
  - Container security scanning

- 📊 **Enhanced Reporting**
  - Additional report formats (JSON, XML, HTML)
  - Custom report templates
  - Improved visualization

- 🔧 **Integrations**
  - CI/CD pipeline integrations (GitHub Actions, GitLab CI)
  - SIEM integrations (Splunk, ELK)
  - Ticketing systems (Jira, ServiceNow)

- 🐳 **Deployment**
  - Docker containerization
  - Kubernetes deployment
  - Cloud deployment guides

## 💻 Development Guidelines

### Code Style

#### Bash Scripts
- Use shellcheck for linting
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use meaningful variable names
- Add comments for complex logic
- Use `set -e` for error handling

```bash
# Good
function check_dependencies() {
    local required_tools=("curl" "dig" "openssl")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: $tool is not installed"
            return 1
        fi
    done
}

# Bad
function check_deps() {
    for i in curl dig openssl; do
        command -v $i || exit 1
    done
}
```

#### Python Code
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where appropriate
- Write docstrings for functions
- Use meaningful variable names

```python
# Good
def send_assessment_report(report_path: str, recipient: str) -> bool:
    """
    Send security assessment report via email.

    Args:
        report_path: Path to the PDF report file
        recipient: Email address of the recipient

    Returns:
        True if email sent successfully, False otherwise
    """
    # Implementation
    pass

# Bad
def send(r, e):
    # Implementation
    pass
```

### Testing

- Write tests for new features
- Ensure existing tests pass
- Test on multiple environments (Linux, macOS)
- Test with different tool versions

### Documentation

- Update README.md if adding new features
- Add inline comments for complex logic
- Include usage examples
- Update CHANGELOG.md

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(web): add support for API security testing

Added new module to assess REST API security including:
- Authentication mechanism analysis
- Rate limiting detection
- CORS configuration review

Closes #123
```

```
fix(network): correct CVE severity calculation

Fixed bug where CVSS scores were not properly parsed from
NVD API responses, causing incorrect risk ratings.

Fixes #456
```

## 🐛 Reporting Issues

### Before Reporting

1. **Search existing issues** to avoid duplicates
2. **Test with latest version** to ensure bug still exists
3. **Gather information** about your environment

### Creating an Issue

Use our issue templates and include:

- **Clear title** describing the problem
- **Description** of the issue
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, version, tool versions)
- **Screenshots** if applicable
- **Relevant logs** or error messages

**Good Issue Example:**
```markdown
### Bug Description
Web assessment fails with SSL error on valid HTTPS sites

### Steps to Reproduce
1. Run: `./run-assessment.sh web --target https://example.com`
2. Script fails at SSL/TLS analysis step
3. Error message: "SSL handshake failed"

### Expected Behavior
Should successfully analyze SSL configuration

### Actual Behavior
Script crashes with OpenSSL error

### Environment
- OS: Ubuntu 22.04
- OpenSSL version: 3.0.2
- Script version: 1.0.0

### Logs
```
Error: openssl s_client connection failed
```
```

## 💡 Feature Requests

We welcome feature suggestions! Please include:

- **Use case** - Why is this feature needed?
- **Description** - What should the feature do?
- **Examples** - How would you use it?
- **Alternatives** - What workarounds exist currently?

## 🔄 Pull Request Process

### Step-by-Step Guide

1. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes** following our guidelines

3. **Test thoroughly**:
   ```bash
   # Test web assessment
   ./run-assessment.sh web --target https://example.com

   # Test network assessment
   ./run-assessment.sh network --target 127.0.0.1 --type quick
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Keep your fork updated**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request** on GitHub

### PR Requirements

Your pull request should:

- ✅ Have a clear, descriptive title
- ✅ Reference related issues (e.g., "Closes #123")
- ✅ Include a detailed description of changes
- ✅ Add tests if applicable
- ✅ Update documentation if needed
- ✅ Pass all existing tests
- ✅ Follow code style guidelines
- ✅ Not include unrelated changes

### PR Template

```markdown
## Description
Brief description of what this PR does

## Related Issues
Fixes #123
Relates to #456

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
Describe how you tested your changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Added/updated tests
- [ ] Updated documentation
- [ ] All tests pass
- [ ] Commit messages follow conventions
```

### Review Process

1. **Automated checks** run on your PR
2. **Maintainers review** your code
3. **Feedback** may be provided for improvements
4. **Approval** and merge once requirements are met

## 🎯 Development Priorities

### High Priority
- Bug fixes affecting core functionality
- Security vulnerabilities
- Critical performance issues

### Medium Priority
- New assessment modules
- Enhanced reporting
- Improved error handling

### Low Priority
- Code style improvements
- Minor refactoring
- Nice-to-have features

## 📝 Documentation Standards

### Code Comments

```bash
# Good
# Check if required security tools are installed
# Returns 0 if all tools available, 1 otherwise
check_security_tools() {
    # Implementation
}

# Bad
# Check tools
check_tools() {
    # Implementation
}
```

### README Updates

When adding new features, update:
- Quick Start section
- Usage examples
- Configuration options
- Requirements list

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in commit history

## 📞 Getting Help

Need help contributing?

- 💬 [GitHub Discussions](https://github.com/arcy24/netsectap-security-framework/discussions)
- 🐛 [GitHub Issues](https://github.com/arcy24/netsectap-security-framework/issues)
- 📧 Email: (to be added when public)

## 📜 Legal

By contributing, you agree that:
- Your contributions will be licensed under the MIT License
- You have the right to contribute the code
- Your contributions are original work

---

**Thank you for contributing to NetSecTap Security Framework!**

Your contributions help make security testing more accessible to everyone.
