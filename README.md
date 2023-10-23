# Asset Pipeline

Asset Pipeline is a shard written to handle 3 types of assets:
- Javascript, by using ESM modules and import maps
- CSS/SASS, by utilizing Node SASS from an import map
- Images

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     asset_pipeline:
       github: amberframework/asset_pipeline
       version: 0.1.0
   ```

2. Run `shards install`

## Usage

```crystal
require "asset_pipeline"

import_map = AssetPipeline::ImportMap.new
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/asset_pipeline/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Seth Tucker](https://github.com/crimson-knight) - creator and maintainer
