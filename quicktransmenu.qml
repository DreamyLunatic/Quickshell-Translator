import Quickshell
import Quickshell.Io // for Process
import QtQuick

PanelWindow {
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    TextArea { id: input }
    Text { id: output }
    Process { id: tr; command: ["trans", "-b", ":ru", input.text] }
}
