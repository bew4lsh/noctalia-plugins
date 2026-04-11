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

    property string editDhlApiKey: cfg.carriers?.dhl?.apiKey ?? defaults.carriers?.dhl?.apiKey ?? ""
    property string editFedexClientId: cfg.carriers?.fedex?.clientId ?? defaults.carriers?.fedex?.clientId ?? ""
    property string editFedexClientSecret: cfg.carriers?.fedex?.clientSecret ?? defaults.carriers?.fedex?.clientSecret ?? ""
    property string editUpsClientId: cfg.carriers?.ups?.clientId ?? defaults.carriers?.ups?.clientId ?? ""
    property string editUpsClientSecret: cfg.carriers?.ups?.clientSecret ?? defaults.carriers?.ups?.clientSecret ?? ""
    property string editUspsConsumerKey: cfg.carriers?.usps?.consumerKey ?? defaults.carriers?.usps?.consumerKey ?? ""
    property string editUspsConsumerSecret: cfg.carriers?.usps?.consumerSecret ?? defaults.carriers?.usps?.consumerSecret ?? ""
    property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 30
    property var editPackages: []

    property string newTrackingNumber: ""
    property string newCarrier: "dhl"
    property string newLabel: ""

    Component.onCompleted: {
        var pkgs = cfg.packages ?? defaults.packages ?? [];
        editPackages = JSON.parse(JSON.stringify(pkgs));
    }

    function addPackage() {
        if (root.newTrackingNumber === "" || root.newCarrier === "") return;
        var pkgs = root.editPackages.slice();
        pkgs.push({
            trackingNumber: root.newTrackingNumber,
            carrier: root.newCarrier,
            label: root.newLabel
        });
        root.editPackages = pkgs;
        root.newTrackingNumber = "";
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
        label: "DHL"
        description: "Get your API key from developer.dhl.com"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "API Key"
        placeholderText: "Enter your DHL API key"
        text: root.editDhlApiKey
        onTextChanged: root.editDhlApiKey = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "FedEx"
        description: "Get credentials from developer.fedex.com"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Client ID"
        placeholderText: "Enter your FedEx client ID"
        text: root.editFedexClientId
        onTextChanged: root.editFedexClientId = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Client Secret"
        placeholderText: "Enter your FedEx client secret"
        text: root.editFedexClientSecret
        onTextChanged: root.editFedexClientSecret = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "UPS"
        description: "Get credentials from developer.ups.com"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Client ID"
        placeholderText: "Enter your UPS client ID"
        text: root.editUpsClientId
        onTextChanged: root.editUpsClientId = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Client Secret"
        placeholderText: "Enter your UPS client secret"
        text: root.editUpsClientSecret
        onTextChanged: root.editUpsClientSecret = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "USPS"
        description: "Get credentials from developer.usps.com"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Consumer Key"
        placeholderText: "Enter your USPS consumer key"
        text: root.editUspsConsumerKey
        onTextChanged: root.editUspsConsumerKey = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Consumer Secret"
        placeholderText: "Enter your USPS consumer secret"
        text: root.editUspsConsumerSecret
        onTextChanged: root.editUspsConsumerSecret = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
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
                        text: modelData.carrier.toUpperCase() + " " + modelData.trackingNumber
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

    NComboBox {
        Layout.fillWidth: true
        label: "Carrier"

        model: [
            { key: "dhl", name: "DHL" },
            { key: "fedex", name: "FedEx" },
            { key: "ups", name: "UPS" },
            { key: "usps", name: "USPS" }
        ]

        currentKey: root.newCarrier
        onSelected: key => root.newCarrier = key
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
            cursorShape: root.newTrackingNumber !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.addPackage()
        }
    }

    Item {
        Layout.preferredHeight: Style.marginL
    }

    function saveSettings() {
        if (!pluginApi) return;

        pluginApi.pluginSettings.carriers = {
            dhl: { apiKey: root.editDhlApiKey },
            fedex: { clientId: root.editFedexClientId, clientSecret: root.editFedexClientSecret },
            ups: { clientId: root.editUpsClientId, clientSecret: root.editUpsClientSecret },
            usps: { consumerKey: root.editUspsConsumerKey, consumerSecret: root.editUspsConsumerSecret }
        };
        pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval;
        pluginApi.pluginSettings.packages = root.editPackages;

        pluginApi.saveSettings();
    }
}
