import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property real contentPreferredWidth: 450
  property real contentPreferredHeight: 200
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool panelAnchorHorizontalCenter: true
  readonly property bool panelAnchorVerticalCenter: true
  readonly property bool allowAttach: false
  anchors.fill: parent

  property var categories: ["definition", "synonyms", "antonyms", "rhymes"]
  property var categoryLabels: ["Definition", "Synonyms", "Antonyms", "Rhymes"]
  property var categoryIcons: ["book", "copy", "arrow-left-right", "music"]

  property int activeCategory: {
    var def = cfg.defaultCategory || defaults.defaultCategory || "definition";
    var idx = categories.indexOf(def);
    return idx >= 0 ? idx : 0;
  }

  property string searchWord: ""

  property var panelOpenScreen: pluginApi?.panelOpenScreen

  onPanelOpenScreenChanged: {
    if (panelOpenScreen && searchInput.inputItem) {
      searchInput.inputItem.forceActiveFocus();
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      // Category selector row
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        Repeater {
          model: root.categories.length

          NIconButton {
            icon: root.categoryIcons[index]
            tooltipText: root.categoryLabels[index]
            colorBg: index === root.activeCategory ? Color.mPrimary : Color.mSurfaceVariant
            colorFg: index === root.activeCategory ? Color.mOnPrimary : Color.mOnSurface
            colorBgHover: index === root.activeCategory ? Color.mPrimary : Color.mHover
            colorFgHover: index === root.activeCategory ? Color.mOnPrimary : Color.mOnHover

            onClicked: {
              root.activeCategory = index;
              if (searchInput.inputItem) {
                searchInput.inputItem.forceActiveFocus();
              }
            }
          }
        }

        Item { Layout.fillWidth: true }

        NIconButton {
          icon: "settings"
          onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest) {
              BarService.openPluginSettings(screen, pluginApi.manifest);
            }
          }
        }
      }

      // Search input
      NTextInput {
        id: searchInput
        Layout.fillWidth: true
        placeholderText: root.categoryLabels[root.activeCategory] + " lookup..."
        fontSize: Style.fontSizeM

        onTextChanged: root.searchWord = text

        Component.onCompleted: {
          if (searchInput.inputItem) {
            searchInput.inputItem.forceActiveFocus();
            searchInput.inputItem.Keys.onPressed.connect(function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.searchWord.trim().length > 0) {
                  var mainInst = root.pluginApi?.mainInstance;
                  if (mainInst) {
                    mainInst.lookupWord(root.searchWord, root.categories[root.activeCategory]);
                  }
                  var closeAfter = root.cfg.closeAfterLookup ?? root.defaults.closeAfterLookup ?? true;
                  if (closeAfter && root.pluginApi) {
                    root.pluginApi.closePanel();
                  }
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Escape) {
                if (root.pluginApi) {
                  root.pluginApi.closePanel();
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Tab) {
                root.activeCategory = (root.activeCategory + 1) % root.categories.length;
                event.accepted = true;
              } else if (event.key === Qt.Key_Backtab) {
                root.activeCategory = (root.activeCategory - 1 + root.categories.length) % root.categories.length;
                event.accepted = true;
              }
            });
          }
        }
      }

      // Hint text
      NText {
        Layout.fillWidth: true
        text: root.searchWord.trim().length > 0
          ? root.categoryLabels[root.activeCategory] + " for '" + root.searchWord.trim() + "' — press Enter"
          : "Type a word and press Enter"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        elide: Text.ElideRight
      }
    }
  }
}
