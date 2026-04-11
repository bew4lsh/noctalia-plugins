import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string editApiKey: cfg.apiKey || defaults.apiKey || ""
    property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 30
    property var editPackages: []

    property string newTrackingNumber: ""
    property string newSlug: ""
    property string newLabel: ""

    Component.onCompleted: {
        var pkgs = cfg.packages ?? defaults.packages ?? [];
        editPackages = JSON.parse(JSON.stringify(pkgs));
    }

    function addPackage() {
        if (root.newTrackingNumber === "" || root.newSlug === "") return;
        var pkgs = root.editPackages.slice();
        pkgs.push({
            trackingNumber: root.newTrackingNumber,
            slug: root.newSlug,
            label: root.newLabel
        });
        root.editPackages = pkgs;
        root.newTrackingNumber = "";
        root.newSlug = "";
        root.newLabel = "";
    }

    function removePackage(idx) {
        var pkgs = root.editPackages.slice();
        pkgs.splice(idx, 1);
        root.editPackages = pkgs;
    }

    spacing: Style.marginM

    NText {
        text: "Package Tracking Settings"
        font.pointSize: Style.fontSizeXL
        font.bold: true
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "AfterShip API"
        description: "Get your API key from aftership.com/apps/api"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "API Key"
        placeholderText: "Enter your AfterShip API key"
        text: root.editApiKey
        onTextChanged: root.editApiKey = text
    }

    NComboBox {
        Layout.fillWidth: true
        label: "Refresh Interval"
        description: "How often to check for status updates"

        model: [
            { key: 15, name: "15 minutes" },
            { key: 30, name: "30 minutes" },
            { key: 60, name: "1 hour" },
            { key: 120, name: "2 hours" }
        ]

        currentKey: root.editRefreshInterval
        onSelected: key => root.editRefreshInterval = key
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "Tracked Packages"
        description: "Manage packages you want to track"
    }

    Repeater {
        model: root.editPackages

        NBox {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: pkgRow.implicitHeight + Style.margin2M

            RowLayout {
                id: pkgRow
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    NText {
                        text: modelData.label || modelData.trackingNumber
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                    }

                    NText {
                        text: modelData.slug.toUpperCase() + " " + modelData.trackingNumber
                        color: Color.mSecondary
                    }
                }

                NIcon {
                    icon: "trash"
                    color: removeMouse.containsMouse ? Color.mPrimary : Color.mSecondary

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removePackage(index)
                    }
                }
            }
        }
    }

    NText {
        visible: root.editPackages.length === 0
        text: "No packages tracked yet."
        color: Color.mSecondary
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "Add Package"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Tracking Number"
        placeholderText: "e.g. 1Z999AA10123456784"
        text: root.newTrackingNumber
        onTextChanged: root.newTrackingNumber = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Carrier Slug"
        placeholderText: "e.g. usps, ups, fedex, dhl, amazon"
        text: root.newSlug
        onTextChanged: root.newSlug = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Label (optional)"
        placeholderText: "e.g. New headphones"
        text: root.newLabel
        onTextChanged: root.newLabel = text
    }

    NBox {
        Layout.fillWidth: true
        implicitHeight: addRow.implicitHeight + Style.margin2M

        RowLayout {
            id: addRow
            anchors.fill: parent
            anchors.margins: Style.marginM

            Item { Layout.fillWidth: true }

            NIcon {
                icon: "plus"
                color: Color.mPrimary
            }

            NText {
                text: "Add Package"
                color: Color.mPrimary
                font.weight: Style.fontWeightBold
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.newTrackingNumber !== "" && root.newSlug !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.addPackage()
        }
    }

    Item {
        Layout.preferredHeight: Style.marginL
    }

    function saveSettings() {
        if (!pluginApi) return;

        pluginApi.pluginSettings.apiKey = root.editApiKey;
        pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval;
        pluginApi.pluginSettings.packages = root.editPackages;

        pluginApi.saveSettings();
    }
}
