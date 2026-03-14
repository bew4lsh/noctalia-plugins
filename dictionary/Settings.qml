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
    description: "Which lookup type to show first in results"

    model: [
      { key: "definition", name: "Definition" },
      { key: "synonyms", name: "Synonyms" },
      { key: "antonyms", name: "Antonyms" },
      { key: "rhymes", name: "Rhymes" }
    ]

    currentKey: root.editDefaultCategory
    onSelected: key => root.editDefaultCategory = key
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

    pluginApi.saveSettings();
  }
}
