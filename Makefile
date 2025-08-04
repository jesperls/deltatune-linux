# Installation directory
INSTALL_DIR = /etc/xdg/quickshell/deltatune

# Default target
install: create_dirs install_files

# Create necessary directories
create_dirs:
	mkdir -p $(INSTALL_DIR)
	mkdir -p $(INSTALL_DIR)/fonts

# Install files
install_files:
	cp ./shell.qml $(INSTALL_DIR)/
	cp ./fonts/*.png $(INSTALL_DIR)/fonts/
	cp ./fonts/*.js $(INSTALL_DIR)/fonts/

# Uninstall target
uninstall:
	rm -rf $(INSTALL_DIR)

# Clean target (no build artifacts to clean in this case)
clean:

# Help target
help:
	@echo "Available targets:"
	@echo "  install   - Install files to $(INSTALL_DIR)"
	@echo "  uninstall - Remove installed files"
	@echo "  clean     - Clean build artifacts (no-op)"
	@echo "  help      - Show this help message"

.PHONY: install create_dirs install_files uninstall clean help
