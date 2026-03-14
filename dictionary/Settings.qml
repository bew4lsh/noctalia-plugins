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

  property string editDefinitionUrl:
    cfg.definitionUrl ||
    defaults.definitionUrl ||
    "https://www.powerthesaurus.org/{word}/definitions"

  property string editSynonymsUrl:
    cfg.synonymsUrl ||
    defaults.synonymsUrl ||
    "https://www.powerthesaurus.org/{word}/synonyms"

  property string editAntonymsUrl:
    cfg.antonymsUrl ||
    defaults.antonymsUrl ||
    "https://www.powerthesaurus.org/{word}/antonyms"

  property string editRhymesUrl:
    cfg.rhymesUrl ||
    defaults.rhymesUrl ||
    "https://www.powerthesaurus.org/{word}/rhymes"

  property string editDefaultCategory:
    cfg.defaultCategory ||
    defaults.defaultCategory ||
    "definition"

  property bool editCloseAfterLookup:
    cfg.closeAfterLookup ??
    defaults.closeAfterLookup ??
    true

  spacing: Style.marginM

  // Title
  NText {
    text: "Dictionary Settings"
    font.pointSize: Style.fontSizeXL
    font.bold: true
  }

  NText {
    text: "Configure URL templates and lookup behavior. Use {word} as a placeholder for the search term."
    color: Color.mSecondary
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  // URL Templates
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: "URL Templates"
    description: "Customize which websites are used for each lookup type"
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Definition URL"
    placeholderText: "https://www.powerthesaurus.org/{word}/definitions"
    text: root.editDefinitionUrl
    onTextChanged: root.editDefinitionUrl = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Synonyms URL"
    placeholderText: "https://www.powerthesaurus.org/{word}/synonyms"
    text: root.editSynonymsUrl
    onTextChanged: root.editSynonymsUrl = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Antonyms URL"
    placeholderText: "https://www.powerthesaurus.org/{word}/antonyms"
    text: root.editAntonymsUrl
    onTextChanged: root.editAntonymsUrl = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Rhymes URL"
    placeholderText: "https://www.powerthesaurus.org/{word}/rhymes"
    text: root.editRhymesUrl
    onTextChanged: root.editRhymesUrl = text
  }

  // Behavior
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: "Behavior"
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Default Category"
    description: "Which lookup type to select when opening the panel"

    model: [
      { key: "definition", name: "Definition" },
      { key: "synonyms", name: "Synonyms" },
      { key: "antonyms", name: "Antonyms" },
      { key: "rhymes", name: "Rhymes" }
    ]

    currentKey: root.editDefaultCategory
    onSelected: key => root.editDefaultCategory = key
  }

  NToggle {
    Layout.fillWidth: true
    label: "Close After Lookup"
    description: "Automatically close the panel after opening a URL"
    checked: root.editCloseAfterLookup
    onToggled: checked => root.editCloseAfterLookup = checked
  }

  // Keybind info
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: "Keybind Setup"
    description: "To toggle the dictionary panel with a keyboard shortcut, add this to your compositor config:"
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: commandText.implicitHeight + Style.marginS * 2
    color: Color.mSurfaceVariant
    radius: Style.radiusS

    NText {
      id: commandText
      anchors.fill: parent
      anchors.margins: Style.marginS
      text: "qs -c \"noctalia-shell\" ipc call plugin:dictionary toggle"
      font.family: "monospace"
      pointSize: Style.fontSizeS
      color: Color.mPrimary
      wrapMode: Text.WrapAnywhere
    }
  }

  NText {
    Layout.fillWidth: true
    text: "Niri: Mod+Shift+D { spawn \"qs\" \"-c\" \"noctalia-shell\" \"ipc\" \"call\" \"plugin:dictionary\" \"toggle\"; }"
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
    wrapMode: Text.WordWrap
  }

  // Bottom spacing
  Item {
    Layout.preferredHeight: Style.marginL
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.definitionUrl = root.editDefinitionUrl;
    pluginApi.pluginSettings.synonymsUrl = root.editSynonymsUrl;
    pluginApi.pluginSettings.antonymsUrl = root.editAntonymsUrl;
    pluginApi.pluginSettings.rhymesUrl = root.editRhymesUrl;
    pluginApi.pluginSettings.defaultCategory = root.editDefaultCategory;
    pluginApi.pluginSettings.closeAfterLookup = root.editCloseAfterLookup;

    pluginApi.saveSettings();
  }
}
