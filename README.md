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