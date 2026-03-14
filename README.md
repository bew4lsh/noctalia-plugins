# Dictionary Plugin for Noctalia

Look up words directly from the Noctalia launcher. Supports definitions, synonyms, antonyms, and rhymes via [Power Thesaurus](https://www.powerthesaurus.org/).

Requires **Noctalia 3.9.0+**.

## Usage

1. Open the launcher
2. Type `>dict <word>` (e.g. `>dict hello`)
3. Select a result — Definition, Synonyms, Antonyms, or Rhymes
4. The corresponding page opens in your default browser

## Installation

Add this registry to Noctalia's plugin manager:

```
https://raw.githubusercontent.com/bew4lsh/noctalia-plugins/main/registry.json
```

Then install "Dictionary" from the plugin list.

## Settings

In **Settings > Plugins > Dictionary** you can configure:

- **URL templates** — customize which website is used for each lookup type. Use `{word}` as the placeholder for the search term.
- **Default category** — which lookup type appears first in results.

## License

MIT
