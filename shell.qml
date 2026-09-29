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
    property string target: ":ru"

    PanelWindow {
        id: win

        focusable: true
        implicitWidth: 700
        implicitHeight: 300
        color: "transparent"   // without this you get a white/opaque box

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
            root.result = "…";

            translator.running = true;
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
                input.text = this.text;
                translator.running = true;
            }
        }
    }    // trans из пакета translate-shell: sudo pacman -S translate-shell
    
    Process {
        id: translator

        command: ["trans", "-b", root.target, input.text]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim()
                if (out !== "")
                    root.result = out
                else
                    root.translateOffline(input.text)
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
    function translateOffline(text) {
        const ru = /[А-Яа-яЁё]/.test(text)
        const flat = text.replace(/\n/g, " ")
        argos.write(`${ru ? "ru" : "en"}\t${ru ? "en" : "ru"}\t${flat}\n`)
    }


    // Not used yet
    IpcHandler {
        target: "translator"
        function toggle(): void { win.visible = !win.visible }
    }
}
