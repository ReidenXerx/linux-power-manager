# Contributing to Linux Power Manager

Thank you for your interest in contributing to Linux Power Manager! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or request features
- Provide system information (distribution, version, hardware)
- Include steps to reproduce the issue
- Attach relevant logs or error messages

### Code Contributions
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 🧪 Development Setup

### Prerequisites
- Linux system (preferably VM for testing)
- Bash 4.0+
- Basic shell scripting knowledge

### Local Development
```bash
# Clone your fork
git clone https://github.com/yourusername/linux-power-manager.git
cd linux-power-manager

# Create development branch
git checkout -b feature/my-feature

# Make your changes
# Test in VM or container

# Test installation
./install.sh

# Test functionality
power-control.sh status
power-control.sh list-presets
```

## 📋 Coding Standards

### Shell Scripting Guidelines
- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e`
- Use meaningful variable names
- Quote variables: `"$variable"`
- Use functions for reusable code
- Add comments for complex logic

### Code Style
```bash
# Good examples
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

if [ "$VARIABLE" = "value" ]; then
    action_function "$parameter"
fi

# Use consistent indentation (4 spaces)
```

### Error Handling
```bash
# Always check command success
if ! command_that_might_fail; then
    error "Command failed"
    return 1
fi

# Use proper error messages
error "Failed to install package: $package_name"
```

## 🧪 Testing

### Manual Testing
Test your changes on:
- Ubuntu/Debian systems
- Fedora/RHEL systems  
- Arch Linux systems
- Different hardware configurations

### Test Cases
- Installation on fresh system
- Upgrade from previous version
- Uninstallation
- All power presets
- GPU switching (if applicable)
- Configuration changes

## 📚 Documentation

### README Updates
- Update feature lists
- Add new configuration options
- Update usage examples
- Include troubleshooting for new features

### Code Documentation
- Add comments for complex functions
- Document configuration options
- Include usage examples in docstrings

## 🚀 Release Process

### Version Numbering
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version in scripts and documentation
- Create release notes

### Distribution Testing
Before release, test on:
- Ubuntu LTS (latest)
- Fedora (latest)
- Arch Linux
- openSUSE Leap

## 🎯 Contribution Ideas

### High Priority
- Support for more distributions
- Power consumption monitoring
- Custom preset creation UI
- Better error handling
- Performance optimizations

### Medium Priority
- Desktop environment integrations
- Power usage statistics
- Profile scheduling
- Remote management
- Web interface

### Low Priority
- GUI application
- Mobile notifications
- Cloud sync
- Advanced scripting

## 📝 Pull Request Guidelines

### Before Submitting
- [ ] Code follows style guidelines
- [ ] Tested on at least one distribution
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Commit messages are descriptive

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Ubuntu/Debian
- [ ] Tested on Fedora/RHEL
- [ ] Tested on Arch Linux
- [ ] Tested installation
- [ ] Tested uninstallation

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

## 🐛 Bug Reports

### Information to Include
```markdown
**System Information:**
- Distribution: Ubuntu 22.04
- Kernel: 5.15.0
- Hardware: Laptop/Desktop
- GPU: Intel/NVIDIA/AMD

**Issue Description:**
Clear description of the problem

**Steps to Reproduce:**
1. Run command X
2. See error Y

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Logs:**
```
# Include relevant logs
```

## 🚀 Feature Requests

### Template
```markdown
**Feature Description:**
Clear description of the requested feature

**Use Case:**
Why is this feature needed?

**Proposed Implementation:**
Ideas for how it could work

**Additional Context:**
Any other relevant information
```

## 📞 Getting Help

- **Questions**: GitHub Discussions
- **Chat**: Project Discord/Matrix (if available)
- **Email**: maintainer@email.com

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Linux Power Manager! 🚀
