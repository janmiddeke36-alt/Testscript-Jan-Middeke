#!/bin/zsh

RAW_INPUT=$(osascript -e 'text returned of (display dialog "Bitte geben Sie den Namen des Druckers ein (z. B. ed-d3-005-ca):" default answer "" with title "Drucker-Farbmodus ändern" buttons {"Abbrechen", "Weiter"} default button "Weiter")' 2>/dev/null)

if [ -z "$RAW_INPUT" ]; then
    osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
    exit 0
fi

PRINTER=$(echo "$RAW_INPUT" | tr '[:upper:] \055' '[:lower:]__')

if ! lpstat -p "$PRINTER" >/dev/null 2>&1; then
    osascript -e "display dialog \"Der Drucker „$PRINTER“ wurde auf diesem Mac nicht gefunden.\" buttons {\"OK\"} default button 1 with icon stop"
    osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
    exit 1
fi

MODE=$(osascript -e "button returned of (display dialog \"Welcher Standard-Modus soll für „$PRINTER“ festgelegt werden?\" with title \"Farbmodus wählen\" buttons {\"Abbrechen\", \"Farbe\", \"Schwarz-Weiß\"} default button \"Schwarz-Weiß\")" 2>/dev/null)

if [ -z "$MODE" ] || [ "$MODE" = "Abbrechen" ]; then
    osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
    exit 0
fi

OPTS=$(lpoptions -p "$PRINTER" -l 2>/dev/null)

if [ "$MODE" = "Schwarz-Weiß" ]; then
    OPTION_ARG="print-color-mode-default=monochrome"
    if echo "$OPTS" | grep -q 'ColorModel/.*Grayscale'; then
        OPTION_ARG="ColorModel=Grayscale"
    elif echo "$OPTS" | grep -q 'ColorModel/.*Gray'; then
        OPTION_ARG="ColorModel=Gray"
    elif echo "$OPTS" | grep -q 'BRMonoColor/.*Mono'; then
        OPTION_ARG="BRMonoColor=Mono"
    elif echo "$OPTS" | grep -q 'CNColorMode/.*mono'; then
        OPTION_ARG="CNColorMode=mono"
    fi
else
    OPTION_ARG="print-color-mode-default=color"
    if echo "$OPTS" | grep -q 'ColorModel/.*Auto'; then
        OPTION_ARG="ColorModel=Auto"
    elif echo "$OPTS" | grep -q 'ColorModel/.*RGB'; then
        OPTION_ARG="ColorModel=RGB"
    elif echo "$OPTS" | grep -q 'ColorModel/.*Color'; then
        OPTION_ARG="ColorModel=Color"
    elif echo "$OPTS" | grep -q 'ColorModel/.*Default'; then
        OPTION_ARG="ColorModel=Default"
    elif echo "$OPTS" | grep -q 'BRMonoColor/.*Color'; then
        OPTION_ARG="BRMonoColor=Color"
    elif echo "$OPTS" | grep -q 'CNColorMode/.*color'; then
        OPTION_ARG="CNColorMode=color"
    fi
fi

if osascript -e "do shell script \"lpadmin -p '$PRINTER' -o $OPTION_ARG\" with administrator privileges" >/dev/null 2>&1; then
    osascript -e "display dialog \"Der Drucker „$PRINTER“ wurde erfolgreich auf $MODE umgestellt.\" buttons {\"Fertig\"} default button 1 with icon note"
fi

osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
exit 0
