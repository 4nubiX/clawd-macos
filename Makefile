# Atajos para compilar y probar Clawd. Crece en la tarea 9.
.PHONY: test preview clean

test:
	swift test

preview:
	mkdir -p build
	swift run clawd-preview Resources/Sprites build/preview.png

clean:
	rm -rf .build build
