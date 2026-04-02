# rules_ng2

`rules_ng2` is the source tree for fancyss node-shunt assets.

- `site/` stores normalized domain assets used as the primary source of truth.
- `ip/` stores normalized CIDR assets used as the primary source of truth.
- `meta/assets.json` defines where generated assets come from.
- `meta/presets.json` defines the user-facing shunt presets and how they compose site/ip assets.
- `meta/rule_counts.json` is generated summary data for asset/preset counts.
- `dat/` is generated output for the geodata backend (`geosite.dat` / `geoip.dat`).

Source-of-truth lives here, parallel to `rules_ng`. Package runtime files are mirrored into `fancyss/ss/rules_ng2/`.

Update command:

```bash
scripts/update_geodata_assets.sh
```

Offline regeneration from existing `site/` and `ip/` assets:

```bash
scripts/update_geodata_assets.sh --no-fetch
```

Current normalized formats:

- `site/*.txt`
  - `full:example.com`
  - `domain:example.com`
  - `keyword:example`
- `ip/*.txt`
  - `1.2.3.0/24`
  - `2001:db8::/32`
- `dat/geosite.dat`
- `dat/geoip.dat`
- `meta/rule_counts.json`

Current direction:

- repo keeps source assets as clear text
- package/runtime stores geodata files and metadata
- current runtime can use text backend or hidden geodata backend; text backend may export from geodata through `geotool`
- preset counts in `fancyss/res/shunt_manifest.json.js` are now generated from `geotool stat / geoip-stat` via `meta/rule_counts.json`
