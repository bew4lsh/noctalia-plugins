import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string device: cfg.device ?? defaults.device ?? ":white:kbd_backlight"

  property real brightness: 0
  property real maxBrightness: 1
  property bool ready: false

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  readonly property real contentWidth: isVertical ? barHeight - Style.marginL : capsuleHeight
  readonly property real contentHeight: isVertical ? capsuleHeight : capsuleHeight

  visible: ready
  opacity: ready ? 1.0 : 0.0
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function getIcon() {
    if (!ready || brightness <= 0.001) return "keyboard-off";
    return "keyboard";
  }

  function refreshBrightness() {
    readProc.running = true;
  }

  Component.onCompleted: refreshBrightness()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refreshBrightness()
  }

  Process {
    id: readProc
    command: ["brightnessctl", "-m", "-d", root.device, "info"]
    stdout: StdioCollector {
      onStreamFinished: {
        var line = text.trim();
        if (line === "") return;
        // -m format: device,class,current,percent,max
        var parts = line.split(",");
        if (parts.length >= 5) {
          var current = parseInt(parts[2]);
          var max = parseInt(parts[4]);
          if (!isNaN(current) && !isNaN(max) && max > 0) {
            root.maxBrightness = max;
            root.brightness = current / max;
            root.ready = true;
          }
        }
      }
    }
  }

  Rectangle {
    id: capsule
    anchors.centerIn: parent
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: root.getIcon()
      color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
      applyUiScale: true
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    onEntered: {
      var pct = Math.round(root.brightness * 100);
      TooltipService.show(root, [["Keyboard", pct + "%"]], BarService.getTooltipDirection(root.screen?.name));
    }
    onExited: TooltipService.hide()
    onClicked: {
      if (pluginApi) pluginApi.openPanel(root.screen, root);
    }
  }
}
