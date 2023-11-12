# Asset Pipeline

Asset Pipeline is a shard written to handle 3 types of assets:
- Javascript, by using ESM modules and import maps  (Done! v0.34)
- CSS/SASS, by utilizing Node SASS from an import map (TBD)
- Images (TBD)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     asset_pipeline:
       github: amberframework/asset_pipeline
       version: 0.34.0
   ```

2. Run `shards install`

## Usage

For the fullest examples, please view the docs for `AssetPipeline::FrontLoader`.

The `FrontLoader` class is the primary class to use for handling all of your assets with the AssetPipeline.

## Development

Thank you for your interest in contributing! Please join the Amber (discord)[https://discord.gg/JKCczAEh4D] to get the most up to date information.

If you're interested in contributing, please check out the open github issues and then ask about them in the discord group to see if anyone has made any attempts or has additional information about the issue.

## Contributing

1. Fork it (<https://github.com/your-github-user/asset_pipeline/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Seth Tucker](https://github.com/crimson-knight) - creator and maintainer
