import QtQuick
import QtQuick.Layouts
import Quickshell
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
    property var packages: cfg.packages ?? defaults.packages ?? []

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real barHeight: Style.getBarHeightForScreen(screenName)
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

    readonly property real contentWidth: isVertical ? barHeight - Style.marginL : capsuleHeight
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        NIcon {
            anchors.centerIn: parent
            icon: "package"
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
            var count = root.packages.length;
            var label = count === 1 ? "package" : "packages";
            TooltipService.show(root, [["Tracking", count + " " + label]], BarService.getTooltipDirection(root.screen?.name));
        }
        onExited: TooltipService.hide()
        onClicked: {
            if (pluginApi) pluginApi.openPanel(root.screen, root);
        }
    }
}
