---
name: mas
inspects: true
---
asserts a Mac app is installed and up-to-date from the App Store via the [`mas` utility](https://github.com/argon/mas). App ID is required and can be obtained from the `mas list` command; name is optional.

### Usage

```bash
> mas 497799835 Xcode    (installs/upgrades Xcode)
```
