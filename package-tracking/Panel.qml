import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: 450 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string apiKey: cfg.apiKey ?? defaults.apiKey ?? ""
    readonly property var packages: cfg.packages ?? defaults.packages ?? []
    readonly property int refreshMinutes: cfg.refreshInterval ?? defaults.refreshInterval ?? 30

    property var trackingData: ({})
    property int fetchIndex: -1
    property bool loading: false
    property int expandedIndex: -1

    function statusLabel(tag) {
        var labels = {
            "Pending": "Pending",
            "InfoReceived": "Info Received",
            "InTransit": "In Transit",
            "OutForDelivery": "Out for Delivery",
            "AttemptFail": "Failed Attempt",
            "Delivered": "Delivered",
            "AvailableForPickup": "Ready for Pickup",
            "Exception": "Exception",
            "Expired": "Expired"
        };
        return labels[tag] || tag || "Unknown";
    }

    function statusColor(tag) {
        if (tag === "Delivered" || tag === "AvailableForPickup") return Color.mPrimary;
        return Color.mOnSurface;
    }

    function formatDate(dateStr) {
        if (!dateStr) return "";
        var d = new Date(dateStr);
        if (isNaN(d.getTime())) return dateStr;
        return Qt.formatDateTime(d, "MMM d, yyyy");
    }

    function formatCheckpointTime(dateStr) {
        if (!dateStr) return "";
        var d = new Date(dateStr);
        if (isNaN(d.getTime())) return dateStr;
        return Qt.formatDateTime(d, "MMM d, h:mm AP");
    }

    function fetchAll() {
        if (root.apiKey === "" || root.packages.length === 0) return;
        root.fetchIndex = 0;
        root.loading = true;
        fetchNext();
    }

    function fetchNext() {
        if (root.fetchIndex >= root.packages.length) {
            root.loading = false;
            return;
        }
        var pkg = root.packages[root.fetchIndex];
        var url = "https://api.aftership.com/v4/trackings/" + pkg.slug + "/" + pkg.trackingNumber;
        getProc.command = ["curl", "-s",
                           "-H", "aftership-api-key: " + root.apiKey,
                           "-H", "Content-Type: application/json",
                           url];
        getProc.running = true;
    }

    Component.onCompleted: fetchAll()

    Timer {
        interval: root.refreshMinutes * 60000
        running: root.apiKey !== "" && root.packages.length > 0
        repeat: true
        onTriggered: root.fetchAll()
    }

    Process {
        id: getProc
        stdout: StdioCollector {
            onStreamFinished: {
                var response;
                try { response = JSON.parse(text); } catch (e) {
                    root.fetchIndex++;
                    root.fetchNext();
                    return;
                }

                var pkg = root.packages[root.fetchIndex];
                var key = pkg.trackingNumber;

                if (response.meta && response.meta.code === 4004) {
                    var body = JSON.stringify({
                        tracking: {
                            tracking_number: pkg.trackingNumber,
                            slug: pkg.slug,
                            title: pkg.label || ""
                        }
                    });
                    createProc.command = ["curl", "-s", "-X", "POST",
                                          "-H", "aftership-api-key: " + root.apiKey,
                                          "-H", "Content-Type: application/json",
                                          "-d", body,
                                          "https://api.aftership.com/v4/trackings"];
                    createProc.running = true;
                    return;
                }

                if (response.data && response.data.tracking) {
                    var updated = Object.assign({}, root.trackingData);
                    updated[key] = response.data.tracking;
                    root.trackingData = updated;
                }

                root.fetchIndex++;
                root.fetchNext();
            }
        }
    }

    Process {
        id: createProc
        stdout: StdioCollector {
            onStreamFinished: {
                var response;
                try { response = JSON.parse(text); } catch (e) {}

                if (response && response.data && response.data.tracking) {
                    var pkg = root.packages[root.fetchIndex];
                    var updated = Object.assign({}, root.trackingData);
                    updated[pkg.trackingNumber] = response.data.tracking;
                    root.trackingData = updated;
                }

                root.fetchIndex++;
                root.fetchNext();
            }
        }
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
                        icon: "package"
                        pointSize: Style.fontSizeXXL
                        color: Color.mPrimary
                    }

                    NText {
                        text: "Package Tracking"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NIcon {
                        id: refreshIcon
                        icon: "refresh"
                        pointSize: Style.fontSizeL
                        color: refreshMouse.containsMouse ? Color.mPrimary : Color.mSecondary

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fetchAll()
                        }
                    }
                }
            }

            NText {
                visible: root.apiKey === ""
                text: "Set your AfterShip API key in plugin settings."
                color: Color.mSecondary
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            NText {
                visible: root.apiKey !== "" && root.packages.length === 0
                text: "No packages tracked. Add packages in plugin settings."
                color: Color.mSecondary
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            NText {
                visible: root.loading
                text: "Refreshing..."
                color: Color.mSecondary
            }

            ListView {
                visible: root.packages.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.packages
                spacing: Style.marginS
                clip: true

                delegate: NBox {
                    id: packageDelegate

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: packageColumn.implicitHeight + Style.margin2M

                    property var tracking: root.trackingData[modelData.trackingNumber] || null
                    property bool expanded: root.expandedIndex === index

                    ColumnLayout {
                        id: packageColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Style.marginM
                        spacing: Style.marginS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                NText {
                                    text: packageDelegate.modelData.label || packageDelegate.modelData.trackingNumber
                                    pointSize: Style.fontSizeL
                                    font.weight: Style.fontWeightBold
                                    color: Color.mOnSurface
                                }

                                NText {
                                    visible: packageDelegate.modelData.label !== ""
                                    text: packageDelegate.modelData.slug.toUpperCase() + " " + packageDelegate.modelData.trackingNumber
                                    color: Color.mSecondary
                                }
                            }

                            NText {
                                text: packageDelegate.tracking ? root.statusLabel(packageDelegate.tracking.tag) : "..."
                                color: packageDelegate.tracking ? root.statusColor(packageDelegate.tracking.tag) : Color.mSecondary
                            }

                            NIcon {
                                icon: packageDelegate.expanded ? "chevron-up" : "chevron-down"
                                color: Color.mSecondary
                            }
                        }

                        NText {
                            visible: packageDelegate.tracking && packageDelegate.tracking.expected_delivery
                            text: "Expected: " + (packageDelegate.tracking ? root.formatDate(packageDelegate.tracking.expected_delivery) : "")
                            color: Color.mSecondary
                        }

                        NDivider {
                            visible: packageDelegate.expanded && packageDelegate.tracking && packageDelegate.tracking.checkpoints && packageDelegate.tracking.checkpoints.length > 0
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: (packageDelegate.expanded && packageDelegate.tracking && packageDelegate.tracking.checkpoints) ? packageDelegate.tracking.checkpoints : []

                            ColumnLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: Style.marginS

                                    NText {
                                        text: root.formatCheckpointTime(modelData.checkpoint_time)
                                        color: Color.mSecondary
                                    }

                                    NText {
                                        visible: modelData.location !== undefined && modelData.location !== ""
                                        text: modelData.location || ""
                                        color: Color.mSecondary
                                    }
                                }

                                NText {
                                    text: modelData.message || ""
                                    color: Color.mOnSurface
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expandedIndex = (root.expandedIndex === packageDelegate.index) ? -1 : packageDelegate.index
                    }
                }
            }
        }
    }
}
