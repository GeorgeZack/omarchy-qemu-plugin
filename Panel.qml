import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "dix.qemu"
  ipcTarget: "dix.qemu"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color accent: service.runningCount > 0 ? "#50fa7b" : Qt.darker(foreground, 1.55)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: service
  }

  IpcHandler {
    target: root.ipcTarget
    function refresh(): string { service.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        implicitWidth: Style.space(24)
        implicitHeight: Style.space(20)
        Text {
          anchors.centerIn: parent
          text: "󰟀"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.space(13)
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(col.implicitHeight, Style.space(500))

    Column {
      id: col
      width: parent.width
      spacing: Style.space(12)

      PanelHero {
        width: parent.width
        title: "QEMU VMs"
        meta: service.runningCount > 0
          ? service.runningCount + " corriendo"
          : "Todas detenidas"
        foreground: root.foreground
        fontFamily: root.fontFamily
        iconOpacity: service.runningCount > 0 ? 1.0 : 0.5
        iconComponent: Component {
          Text {
            text: "󰟀"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
          }
        }
      }

      PanelSeparator {
        foreground: root.foreground
      }

      Column {
        width: parent.width
        spacing: Style.space(6)
        padding: Style.space(4)

        Repeater {
          model: service.vms
          delegate: Item {
            required property var modelData
            width: parent.width - Style.space(8)
            implicitHeight: modelData.state === "running"
              ? Style.space(44) + Style.space(52)
              : Style.space(44)

            readonly property bool isRunning: modelData.state === "running"

            Column {
              anchors.fill: parent
              spacing: 0

              RowLayout {
                width: parent.width
                height: Style.space(44)
                spacing: Style.space(8)

                Text {
                  text: isRunning ? "󰐊" : "󰓛"
                  color: isRunning ? "#50fa7b" : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.space(14)
                  leftPadding: Style.space(8)
                }

                Column {
                  Layout.fillWidth: true
                  spacing: Style.space(1)

                  Text {
                    text: modelData.name
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: isRunning
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Text {
                    text: isRunning ? "Corriendo" : "Detenida"
                    color: isRunning ? "#50fa7b" : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Rectangle {
                  width: Style.space(64)
                  height: Style.space(28)
                  radius: Style.space(4)
                  color: isRunning
                    ? Qt.rgba(1, 0.2, 0.2, 0.15)
                    : Qt.rgba(0.31, 0.98, 0.48, 0.15)

                  Text {
                    anchors.centerIn: parent
                    text: isRunning ? "Apagar" : "Iniciar"
                    color: isRunning ? "#ff5555" : "#50fa7b"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !service.busy
                    onClicked: {
                      if (isRunning) service.stop(modelData.name)
                      else {
                        service.start(modelData.name)
                        service.open(modelData.name)
                      }
                    }
                  }
                }
              }

              Column {
                visible: isRunning
                width: parent.width
                spacing: Style.space(2)
                leftPadding: Style.space(30)
                bottomPadding: Style.space(8)

                Text {
                  visible: modelData.ip !== ""
                  text: "IP: " + modelData.ip
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Text {
                  visible: modelData.ram !== ""
                  text: "RAM: " + modelData.ram + " / " + modelData.ramTotal + " MB"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Text {
                  visible: modelData.disk !== ""
                  text: "Disco: " + modelData.disk + " / " + modelData.diskTotal + " GB"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }
  }
}
