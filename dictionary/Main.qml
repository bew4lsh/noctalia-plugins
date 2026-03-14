import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  function buildUrl(word, category) {
    var urlKey = category + "Url";
    var template = cfg[urlKey] || defaults[urlKey] || "";
    if (!template) return "";
    return template.replace("{word}", encodeURIComponent(word));
  }

  function lookupWord(word, category) {
    if (!word || word.trim().length === 0) return;
    var url = buildUrl(word.trim(), category);
    if (url) {
      Qt.openUrlExternally(url);
    }
  }

  IpcHandler {
    target: "plugin:dictionary"

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
          root.pluginApi.togglePanel(screen);
        });
      }
    }
  }
}
