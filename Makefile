# Atajos para compilar y probar Clawd. Crece en las tareas 4 y 9.
.PHONY: test clean

test:
	swift test

clean:
	rm -rf .build build
