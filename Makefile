# Atajos para compilar, probar y empaquetar Clawd.
#   make test     → tests del cerebro
#   make preview  → build/preview.png con todas las animaciones
#   make dev      → corre Clawd sin empaquetar (rápido, para desarrollo)
#   make app      → arma build/Clawd.app (firmado localmente)
#   make run      → arma y abre build/Clawd.app
#   make install  → copia Clawd.app a /Applications y lo abre
APP     := build/Clawd.app
BIN_DIR  = $(shell swift build -c release --show-bin-path)

.PHONY: test preview dev build app run install clean

test:
	swift test

preview:
	mkdir -p build
	swift run clawd-preview Resources/Sprites build/preview.png

dev:
	swift run Clawd

build:
	swift build -c release --product Clawd

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$(BIN_DIR)/Clawd" $(APP)/Contents/MacOS/Clawd
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp -R Resources/Sprites $(APP)/Contents/Resources/Sprites
	codesign --force --sign - $(APP)
	@echo "Listo: $(APP)"

run: app
	-pkill -x Clawd
	open $(APP)

install: app
	-pkill -x Clawd
	rm -rf /Applications/Clawd.app
	cp -R $(APP) /Applications/Clawd.app
	open /Applications/Clawd.app

clean:
	rm -rf .build build
