import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 380 * Style.uiScaleRatio
  property real contentPreferredHeight: 160 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string device: cfg.device ?? defaults.device ?? ":white:kbd_backlight"
  readonly property int step: cfg.step ?? defaults.step ?? 10

  property real brightness: 0
  property real maxBrightness: 1
  property bool sliderPressed: false

  function refreshBrightness() {
    readProc.running = true;
  }

  Component.onCompleted: refreshBrightness()

  Process {
    id: readProc
    command: ["brightnessctl", "-m", "-d", root.device, "info"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.sliderPressed) return;
        var line = text.trim();
        if (line === "") return;
        var parts = line.split(",");
        if (parts.length >= 5) {
          var current = parseInt(parts[2]);
          var max = parseInt(parts[4]);
          if (!isNaN(current) && !isNaN(max) && max > 0) {
            root.maxBrightness = max;
            root.brightness = current / max;
          }
        }
      }
    }
  }

  Process {
    id: setProc
    onExited: root.refreshBrightness()
  }

  function applyBrightness(value) {
    value = Math.max(0, Math.min(1, value));
    root.brightness = value;
    var pct = Math.round(value * 100);
    setProc.command = ["brightnessctl", "-d", root.device, "s", pct + "%"];
    setProc.running = true;
  }

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "keyboard"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NText {
            text: "Keyboard Backlight"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: sliderColumn.implicitHeight + Style.margin2M

        ColumnLayout {
          id: sliderColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon {
              icon: root.brightness <= 0.001 ? "keyboard-off" : "keyboard"
              pointSize: Style.fontSizeXL
              color: Color.mOnSurface
            }

            NValueSlider {
              id: brightnessSlider
              from: 0
              to: 1
              value: root.brightness
              stepSize: 0.01
              Layout.fillWidth: true
              text: Math.round(root.brightness * 100) + "%"

              onMoved: value => root.applyBrightness(value)
              onPressedChanged: (pressed, value) => {
                root.sliderPressed = pressed;
                root.applyBrightness(value);
              }
            }
          }
        }
      }
    }
  }
}
