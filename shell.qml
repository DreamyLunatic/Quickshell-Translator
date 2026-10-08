// Окно-переводчик на Quickshell.
// Запуск:  qs -p ./shell.qml
// Enter — перевести, Shift+Enter — новая строка, Esc — закрыть.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    id: root

    property string result: ""
    property string translatedText: "" // Not in use right now
    property string from: ":en" // Not in use right now
    property string target: ":ru"

    property string sourceLang: "auto"
    property string targetLang: "ru"

    property var targetLangs: [
        { name: "English",    code: "en" },
        { name: "Русский",    code: "ru" },
        { name: "Українська", code: "uk" },
        { name: "Gaeilge",    code: "ga" },
        { name: "Deutsch",    code: "de" },
        { name: "Polski",     code: "pl" }
    ]
    property var sourceLangs: [{ name: "Auto", code: "auto" }].concat(targetLangs)
    
    PanelWindow {
        id: win

        focusable: true
        implicitWidth: 700
        implicitHeight: 300
        color: "transparent"

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 12
            color: "#1e1e2e"
        }
        // Overlay — поверх всего; Exclusive — забирает клавиатуру целиком,
        // иначе ввод уйдёт в окно под нами.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        
        FocusScope {
            anchors.fill: parent
            focus: true
            
            Keys.onPressed: (event) => root.handleKey(event)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

                   RowLayout {
                spacing: 12

                Text {
                    text: root.target === ":ru" ? "EN → RU" : "RU → EN"
                    color: "#89b4fa"
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: root.target === ":ru" ? "Tab — сменить направление" : "Tab - change direction"
                    color: "#6c7086"
                    font.pixelSize: 13
                }
                Row {
                    spacing: 8

                    component LangBox: ComboBox {
                        id: box
                        textRole: "name"
                        valueRole: "code"
                        focusPolicy: Qt.NoFocus          // чтобы Tab не уходил в комбобокс
                        implicitWidth: 140
                        implicitHeight: 32

                        background: Rectangle {
                            radius: 8
                            color: "#313244"
                            border.width: 1
                            border.color: box.popup.visible ? "#89b4fa" : "#45475a"
                        }

                        contentItem: Text {
                            leftPadding: 10
                            rightPadding: box.indicator.width + 10
                            text: box.displayText
                            color: "#cdd6f4"
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        indicator: Text {
                            x: box.width - width - 10
                            y: (box.height - height) / 2
                            text: box.popup.visible ? "▴" : "▾"
                            color: "#6c7086"
                            font.pixelSize: 12
                        }

                        // Items in popup list
                        delegate: ItemDelegate {
                            id: del
                            required property var modelData
                            required property int index
                            width: box.width
                            height: 30
                            highlighted: box.highlightedIndex === index

                            contentItem: Text {
                                text: del.modelData.name
                                color: del.highlighted ? "#89b4fa" : "#cdd6f4"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: del.highlighted ? "#45475a" : "transparent"
                            }
                        }

                        popup: Popup {
                            y: box.height + 4
                            width: box.width
                            padding: 4
                            implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: box.popup.visible ? box.delegateModel : null
                                currentIndex: box.highlightedIndex
                                ScrollIndicator.vertical: ScrollIndicator {}
                            }
                            background: Rectangle {
                                radius: 8
                                color: "#1e1e2e"
                                border.width: 1
                                border.color: "#45475a"
                            }
                        }
                    }

                    LangBox {
                        model: root.sourceLangs
                        currentIndex: 0
                        onActivated: root.sourceLang = currentValue
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "→"
                        color: "#6c7086"
                        font.pixelSize: 16
                    }

                    LangBox {
                        model: root.targetLangs
                        currentIndex: 1
                        onActivated: root.targetLang = currentValue
                    }
                }
            }
            RowLayout {
                spacing: 0

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    
                    TextArea {
                        id: input

                        width: parent.width
                        focus: false
                        color: "#cdd6f4"
                        selectionColor: "#585b70"
                        wrapMode: TextArea.Wrap
                        font.pixelSize: 16
                        placeholderText: root.target === ":ru" ? "текст для перевода…" : "translation text..."
                        placeholderTextColor: "#aef0f8"
                    
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                        }
                        
                        Keys.onPressed: (event) => root.handleKey(event)
                    }
                }
            }
            RowLayout {
                ScrollView{
                    id: resultView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    Text {
                        width: resultView.availableWidth
                        text: root.result
                        color: "#a6e3a1"
                        wrapMode: Text.Wrap
                        font.pixelSize: 16
                    }
                }
            }
        }
    }

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Escape:
            Qt.quit();
            break;
        case Qt.Key_Tab:
            root.target = root.target === ":ru" ? ":en" : ":ru";
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (event.modifiers & Qt.ShiftModifier)
                return;            // не принимаем, TextArea вставит перенос
            translate();
            break;
        default:
            return;                // остальное пусть обрабатывается как обычно
        }
        event.accepted = true;
    }

    Process {
        id: clipboard
        command: ["wl-paste", "--no-newline"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.target = /[А-Яа-яЁё]/.test(input.text) ? ":en" : ":ru"
                input.text = this.text;
                root.translate();
            }
        }
    }    // trans из пакета translate-shell: sudo pacman -S translate-shell
    
    Process {
        id: translator

        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim()
                if (out !== "")
                    root.result = out
                else
                {
                    console.log("shit")
                    root.translateOffline(input.text)
                }
            }
        }
    }
    Process {
        id: argos
        running: true
        command: [Quickshell.shellPath("argos-daemon")]
        stdinEnabled: true

        onRunningChanged: console.log("argos running:", running)
        onExited: (code, status) => console.log("argos exited:", code, status)

        stdout: SplitParser {
            onRead: data => root.result = data 
        } 
        stderr: SplitParser { 
            onRead: data => console.log("argos stderr:", data) 
        } 
    }
    
    function translate() {
        root.result = "…"
        translator.command = ["trans", "-b", root.target, input.text]
        translator.running = true
    }

    function translateOffline(text) {
        const flat = text.replace(/\n/g, " ")
        argos.write(`${root.target === ":ru" ? "ru" : "en"}\t${root.target === ":ru" ? "en" : "ru"}\t${flat}\n`)
    }


    // qs ipc call translator toggle
    IpcHandler {
        target: "translator"
        function toggle(): void { 
            win.visible = !win.visible;
            if (win.visible) clipboard.running = true;
        }
    }
}
