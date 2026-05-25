# Supporting File Templates

All templates use `{{name}}` for the lowercase integration name (e.g., `firebase`) and `{{Name}}` for the PascalCase name (e.g., `Firebase`).

## .gitignore

```
# Xcode
#
# gitignore contributors: Feel free to update this file as needed for the integrations.

## User settings
xcuserdata/

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

## Swift Package Manager
/.build/
.netrc
.swiftpm/

# Dependency management files (not needed for libraries)
Packages/
Package.pins

# Example app build artifacts
Example/.build

# Xcode user-specific files
xcuserdata/
*.xcuserstate
DerivedData/

# macOS and editor metadata
.DS_Store
*.swp
*.swo
*.tmp

# Logs
*.log
```

## CODEOWNERS

```
* @rudderlabs/sdk-ios
```

## LICENSE.md

```
### Elastic License 2.0 (ELv2) ###

## Acceptance ##
By using the software, you agree to all of the terms and conditions below.

## Copyright License ##
The licensor grants you a non-exclusive, royalty-free, worldwide, non-sublicensable, non-transferable license to use, copy, distribute, make available, and prepare derivative works of the software, in each case subject to the limitations and conditions below

## Limitations ##
You may not provide the software to third parties as a hosted or managed service, where the service provides users with access to any substantial set of the features or functionality of the software.

You may not move, change, disable, or circumvent the license key functionality in the software, and you may not remove or obscure any functionality in the software that is protected by the license key.

You may not alter, remove, or obscure any licensing, copyright, or other notices of the licensor in the software. Any use of the licensor's trademarks is subject to applicable law.

## Patents ##
The licensor grants you a license, under any patent claims the licensor can license, or becomes able to license, to make, have made, use, sell, offer for sale, import and have imported the software, in each case subject to the limitations and conditions in this license. This license does not cover any patent claims that you cause to be infringed by modifications or additions to the software. If you or your company make any written claim that the software infringes or contributes to infringement of any patent, your patent license for the software granted under these terms ends immediately. If your company makes such a claim, your patent license ends immediately for work on behalf of your company.

## Notices ##
You must ensure that anyone who gets a copy of any part of the software from you also gets a copy of these terms.

If you modify the software, you must include in any modified copies of the software prominent notices stating that you have modified the software.

## No Other Rights ##
These terms do not imply any licenses other than those expressly granted in these terms.

## Termination ##
If you use the software in violation of these terms, such use is not licensed, and your licenses will automatically terminate. If the licensor provides you with a notice of your violation, and you cease all violation of this license no later than 30 days after you receive that notice, your licenses will be reinstated retroactively. However, if you violate these terms after such reinstatement, any additional violation of these terms will cause your licenses to terminate automatically and permanently.

## No Liability ##
As far as the law allows, the software comes as is, without any warranty or condition, and the licensor will not be liable to you for any damages arising out of these terms or the use or nature of the software, under any kind of legal claim.

## Definitions ##
The *licensor* is the entity offering these terms, and the *software* is the software the licensor makes available under these terms, including any portion of it.

*you* refers to the individual or entity agreeing to these terms.

*your company* is any legal entity, sole proprietorship, or other kind of organization that you work for, plus all organizations that have control over, are under the control of, or are under common control with that organization. *control* means ownership of substantially all the assets of an entity, or the power to direct its management and policies by vote, contract, or otherwise. Control can be direct or indirect.

*your licenses* are all the licenses granted to you for the software under these terms.

*use* means anything you do with the software requiring one of your licenses.

*trademark* means trademarks, service marks, and similar rights.
```

## CONTRIBUTING.md

```
# Contributing to RudderStack

Thanks for taking the time and for your help in improving this project!

## Table of contents

- [**RudderStack Contributor Agreement**](#rudderstack-contributor-agreement)
- [**How you can contribute to RudderStack**](#how-you-can-contribute-to-rudderstack)
- [**Committing**](#committing)
- [**Getting help**](#getting-help)

## RudderStack Contributor Agreement

To contribute to this project, we need you to sign the [**Contributor License Agreement ("CLA")**][CLA] for the first commit you make. By agreeing to the [**CLA**][CLA], we can add you to list of approved contributors and review the changes proposed by you.

## How you can contribute to RudderStack

If you come across any issues or bugs, or have any suggestions for improvement, you can navigate to the specific file in the [**repo**](https://github.com/rudderlabs/integration-swift-{{name}}), make the change, and raise a PR.

You can also contribute to any open-source RudderStack project. View our [**GitHub page**](https://github.com/rudderlabs) to see all the different projects.

## Committing

We prefer squash or rebase commits so that all changes from a branch are committed to master as a single commit. All pull requests are squashed when merged, but rebasing prior to merge gives you better control over the commit message.

## Getting help

For any questions, concerns, or queries, you can start by asking a question in our [**Slack**](https://rudderstack.com/join-rudderstack-slack-community/) community.

### We look forward to your feedback on improving this project!


<!----variables---->

[CLA]: https://rudderlabs.wufoo.com/forms/rudderlabs-contributor-license-agreement
```

## .github/pull_request_template.md

```
## Description
<!-- Describe your changes in detail -->

## Type of change
<!-- What types of changes does your code introduce? Put an `x` in all the boxes that apply -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Implementation Details
<!-- Provide a brief explanation of the implementation approach -->

## Checklist
<!-- Put an `x` in all the boxes that apply -->
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Screenshots (if appropriate)
<!-- Add screenshots to help explain your changes -->

## Additional Notes
<!-- Add any other context about the pull request here -->
```

## README.md Template

```markdown
# RudderIntegration{{Name}}

RudderStack Swift SDK device mode integration for {{Name}}.

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/rudderlabs/integration-swift-{{name}}.git", .upToNextMajor(from: "1.0.0"))
```

Or add it via Xcode:
1. Go to **File > Add Package Dependencies**
2. Enter the repository URL: `https://github.com/rudderlabs/integration-swift-{{name}}`
3. Select **Up to Next Major Version** from `1.0.0`

## Usage

### Swift

```swift
import RudderStackAnalytics
import RudderIntegration{{Name}}

let config = Configuration(writeKey: "<WRITE_KEY>", dataPlaneUrl: "<DATA_PLANE_URL>")
let analytics = Analytics(configuration: config)

let {{name}}Integration = {{Name}}Integration()
analytics.add(plugin: {{name}}Integration)
```

### Objective-C

```objc
@import RudderStackAnalytics;
@import RudderIntegration{{Name}};

RSSConfigurationBuilder *builder = [[RSSConfigurationBuilder alloc] initWithWriteKey:@"<WRITE_KEY>"
                                                      dataPlaneUrl:@"<DATA_PLANE_URL>"];
RSSAnalytics *analytics = [[RSSAnalytics alloc] initWithConfiguration:[builder build]];

RSS{{Name}}Integration *{{name}}Integration = [[RSS{{Name}}Integration alloc] init];
[analytics addPlugin:{{name}}Integration];
```

## License

Elastic License 2.0 (ELv2) - see [LICENSE.md](LICENSE.md) for details.
```
