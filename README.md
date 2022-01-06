# CheckLocalizedStrings
*CheckLocalizedStrings* is a Swift script that verifies your `Localizable.strings` files in your project, and emits either a warning or error if something is wrong.

<img width="269" alt="screen shot 2018-04-30 at 12 34 23" src="https://user-images.githubusercontent.com/5389084/39415291-084d9948-4c74-11e8-83e6-ec2bf1e8b0a4.png">

## Features
- [x] Check for **unused keys**
- [x] Check for **missing keys**
- [x] Check for **mismatched parameters**
- [x] Check for **duplicate definitions** of a key

## Installation
Under your Target's Build phase, add a  `Run Script`. Use the path where you copied the script file to. Make sure to include `$PROJECT_DIR` as an argument.

```shell
"${SOURCE_ROOT}"/{PATH_TO_SCRIPT} $PROJECT_DIR
```

### Arguments

The script takes 5 arguments. The first one, already included in the above snippet, is required. The rest are optional.

1. Project directory
2. Localized string function names (comma separated). Default: **NSLocalizedString**
3. Storyboard/XIB localized function variables (comma separated). *(See LocalizableViews in SampleApp for usage)*
4. Ignore files
5. Print all warnings individually (will group similar ones in one message). Default: **false**

If you need to skip argument 3 or 4, you can pass an empty string:

```shell
"${SOURCE_ROOT}"/{PATH_TO_SCRIPT} $PROJECT_DIR NSLocalizedString "" "" true
```

## License

CheckLocalizedStrings is available under the MIT license. See the LICENSE file for more info.