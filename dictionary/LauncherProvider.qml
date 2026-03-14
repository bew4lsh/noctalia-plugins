import QtQuick

Item {
  id: root

  property var pluginApi: null
  property var launcher: null
  property string name: "Dictionary"

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property var categories_: ["definition", "synonyms", "antonyms", "rhymes"]
  property var categoryLabels: ["Definition", "Synonyms", "Antonyms", "Rhymes"]
  property var categoryIcons: ["book", "copy", "arrow-left-right", "music"]

  function buildUrl(word, category) {
    var urlKey = category + "Url";
    var template = cfg[urlKey] || defaults[urlKey] || "";
    if (!template) return "";
    return template.replace("{word}", encodeURIComponent(word));
  }

  function handleCommand(text) {
    return text.startsWith(">dict");
  }

  function commands() {
    return [
      {
        "name": "dict",
        "description": "Look up a word (definitions, synonyms, antonyms, rhymes)",
        "icon": "book",
        "isTablerIcon": true
      }
    ];
  }

  function getResults(text) {
    var word = text.replace(/^>dict\s*/, "").trim();
    if (word.length === 0) {
      return [
        {
          "name": "Type a word to look up",
          "description": "e.g. >dict hello",
          "icon": "book",
          "isTablerIcon": true,
          "onActivate": function() {}
        }
      ];
    }

    var results = [];
    for (var i = 0; i < categories_.length; i++) {
      var cat = categories_[i];
      var label = categoryLabels[i];
      var icon = categoryIcons[i];
      var url = buildUrl(word, cat);

      results.push({
        "name": label,
        "description": word,
        "icon": icon,
        "isTablerIcon": true,
        "onActivate": (function(u) {
          return function() {
            Qt.openUrlExternally(u);
            if (launcher) launcher.close();
          };
        })(url)
      });
    }

    return results;
  }
}
