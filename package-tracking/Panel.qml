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

    readonly property var carriers: cfg.carriers ?? defaults.carriers ?? ({})
    readonly property var packages: cfg.packages ?? defaults.packages ?? []
    readonly property int refreshMinutes: cfg.refreshInterval ?? defaults.refreshInterval ?? 30
    readonly property string scriptPath: Qt.resolvedUrl("tracker.py").toString().replace("file://", "")

    property var trackingData: ({})
    property int fetchIndex: -1
    property bool loading: false
    property int expandedIndex: -1

    function hasCredentials(carrier) {
        var creds = root.carriers[carrier];
        if (!creds) return false;
        if (carrier === "dhl") return creds.apiKey !== "";
        if (carrier === "fedex" || carrier === "ups") return creds.clientId !== "" && creds.clientSecret !== "";
        if (carrier === "usps") return creds.consumerKey !== "" && creds.consumerSecret !== "";
        return false;
    }

    function credentialArgs(carrier) {
        var creds = root.carriers[carrier];
        if (!creds) return [];
        if (carrier === "dhl") return ["--api-key", creds.apiKey];
        if (carrier === "fedex") return ["--client-id", creds.clientId, "--client-secret", creds.clientSecret];
        if (carrier === "ups") return ["--client-id", creds.clientId, "--client-secret", creds.clientSecret];
        if (carrier === "usps") return ["--consumer-key", creds.consumerKey, "--consumer-secret", creds.consumerSecret];
        return [];
    }

    function statusLabel(status) {
        var labels = {
            "pending": "Pending",
            "info_received": "Info Received",
            "in_transit": "In Transit",
            "out_for_delivery": "Out for Delivery",
            "delivered": "Delivered",
            "failed_attempt": "Failed Attempt",
            "exception": "Exception",
            "unknown": "Unknown"
        };
        return labels[status] || status || "Unknown";
    }

    function statusColor(status) {
        if (status === "delivered") return Color.mPrimary;
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
        if (root.packages.length === 0) return;
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
        if (!root.hasCredentials(pkg.carrier)) {
            root.fetchIndex++;
            root.fetchNext();
            return;
        }
        var cmd = ["python3", root.scriptPath, pkg.carrier, pkg.trackingNumber].concat(root.credentialArgs(pkg.carrier));
        trackProc.command = cmd;
        trackProc.running = true;
    }

    Component.onCompleted: fetchAll()

    Timer {
        interval: root.refreshMinutes * 60000
        running: root.packages.length > 0
        repeat: true
        onTriggered: root.fetchAll()
    }

    Process {
        id: trackProc
        stdout: StdioCollector {
            onStreamFinished: {
                var response;
                try { response = JSON.parse(text); } catch (e) {
                    root.fetchIndex++;
                    root.fetchNext();
                    return;
                }

                var pkg = root.packages[root.fetchIndex];
                var updated = Object.assign({}, root.trackingData);
                updated[pkg.trackingNumber] = response;
                root.trackingData = updated;

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
                visible: root.packages.length === 0
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
                                    text: packageDelegate.modelData.carrier.toUpperCase() + " " + packageDelegate.modelData.trackingNumber
                                    color: Color.mSecondary
                                }
                            }

                            NText {
                                text: packageDelegate.tracking ? root.statusLabel(packageDelegate.tracking.status) : "..."
                                color: packageDelegate.tracking ? root.statusColor(packageDelegate.tracking.status) : Color.mSecondary
                            }

                            NIcon {
                                icon: packageDelegate.expanded ? "chevron-up" : "chevron-down"
                                color: Color.mSecondary
                            }
                        }

                        NText {
                            visible: packageDelegate.tracking && packageDelegate.tracking.estimatedDelivery
                            text: "Expected: " + (packageDelegate.tracking ? root.formatDate(packageDelegate.tracking.estimatedDelivery) : "")
                            color: Color.mSecondary
                        }

                        NText {
                            visible: packageDelegate.tracking && packageDelegate.tracking.error
                            text: packageDelegate.tracking ? (packageDelegate.tracking.error || "") : ""
                            color: Color.mError || Color.mSecondary
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
                                        text: root.formatCheckpointTime(modelData.timestamp)
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
