ELPA_DEPENDENCIES=yaml-mode package-lint let-alist

ELPA_ARCHIVES=melpa gnu

LINT_CHECKDOC_FILES=$(wildcard *.el)
LINT_PACKAGE_LINT_FILES=$(wildcard *.el)
LINT_COMPILE_FILES=$(wildcard *.el)

makel.mk:
	# Download makel
	@if [ -f ../makel/makel.mk ]; then \
		ln -s ../makel/makel.mk .; \
	else \
		curl \
		--fail --silent --show-error --insecure --location \
		--retry 9 --retry-delay 9 \
		-O https://github.com/DamienCassou/makel/raw/v0.8.0/makel.mk; \
	fi

# Include makel.mk if present
-include makel.mk
