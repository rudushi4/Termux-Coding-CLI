# Contributing to Termux-Coding-CLI

Thank you for your interest in contributing!

## How to Contribute

### Reporting Issues
- Use GitHub Issues
- Include Termux version and Android version
- Provide steps to reproduce

### Pull Requests
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test on Termux
5. Submit PR with clear description

### Adding Plugins

1. Create `plugins/your-plugin.sh`
2. Follow the template:

```bash
#!/bin/bash
PLUGIN_NAME="your-plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_DEPS="package1 package2"

your_plugin_install() {
    pkg install -y $PLUGIN_DEPS
}

your_plugin_status() {
    echo "Plugin v$PLUGIN_VERSION"
}
```

3. Update `plugins/manager.sh` PLUGINS array
4. Test thoroughly

### Adding AI Providers

1. Create `providers/your-provider.sh`
2. Implement the chat function:

```bash
#!/bin/bash
your_provider_chat() {
    local prompt="$*"
    # API call logic
}
```

3. Update `providers/detect.sh`

## Code Style

- Use bash with `#!/bin/bash` shebang
- Quote variables: `"$var"`
- Use functions for organization
- Add comments for complex logic

## Testing

- Test on real Termux device
- Test with minimal setup
- Verify all plugins work

## License

By contributing, you agree to license your contributions under MIT.
