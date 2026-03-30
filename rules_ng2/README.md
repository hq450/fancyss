# rules_ng2

`rules_ng2` is the source tree for fancyss 3.5.10+ node-shunt domain rules.

- Source-of-truth lives here, parallel to `rules_ng`.
- Package runtime files are copied into `fancyss/ss/rules_ng2/` by `build.sh`.
- `fancyss/scripts/ss_build_shunt_rules_ng2.sh` updates:
  - `rules_ng2/shunt/*.txt`
  - `fancyss/ss/rules_ng2/shunt/*.txt`
  - `fancyss/res/shunt_manifest.json.js`

Current format is plain text Xray domain tokens:

- `full:example.com`
- `domain:example.com`
- `keyword:example`

This layout is reserved for later online updates and possible geosite/geodata generation.
