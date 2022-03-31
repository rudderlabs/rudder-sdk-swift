# Changelog
All notable changes to this project will be documented in this file.

## Version - 1.0.0-beta.1 - 2022-03-23
### Added
- Initial commit.

## Version - 1.0.0-beta.2 - 2022-03-23
### Fix
- Podspec homepage updated.

## Version - 1.0.0-beta.3 - 2022-04-01
### Added
- Public API exposed from RSServerConfig to fetch destination config by Codable.
`func getConfig<T: Codable>(forPlugin plugin: RSDestinationPlugin) -> T?`
- Public APIs for `track`.
`func track(_ eventName: String)`
`func track(_ eventName: String, properties: TrackProperties)`
`func track(_ eventName: String, properties: TrackProperties, option: RSOption)`
- Public APIs for `identify`.
`func identify(_ userId: String)`
`func identify(_ userId: String, traits: IdentifyTraits)`
`func identify(_ userId: String, traits: IdentifyTraits, option: RSOption)`
- Public APIs for `screen`.
`func screen(_ screenName: String)`
`func screen(_ screenName: String, category: String)`
`func screen(_ screenName: String, properties: ScreenProperties)`
`func screen(_ screenName: String, category: String, properties: ScreenProperties)`
`func screen(_ screenName: String, category: String, properties: ScreenProperties, option: RSOption)`
- Public APIs for `group`.
`func group(_ groupId: String)`
`func group(_ groupId: String, traits: GroupTraits)`
`func group(_ groupId: String, traits: GroupTraits, option: RSOption)`
- Public APIs for `alias`.
`func alias(_ newId: String)`
`func alias(_ newId: String, option: RSOption)`

### Fix
- Fixed `context.traits`.
