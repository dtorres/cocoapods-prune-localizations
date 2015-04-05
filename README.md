# Prune Localizations

This plugin removes unused localized files from your app.

Localized resources provided by third parties increase the size of your app and keeping resources your app will never use only bloats it.

##Requirements

Requires CocoaPods 0.36

## Installation

    $ gem install cocoapods-prune-localizations

## Usage

In your Podfile, add this line:

    plugin 'cocoapods-prune-localizations', {:localizations => ["en", "es"]}

This will keep the English and Spanish localizations in the Pods. Modify the localizations to your needs.

##How it works

The plugin traverses the resources provided by Pods and removes references in the Xcode project of `.lproj` files that don't match the list provided.

A special case are `.bundle` file references because they are a [package](http://en.wikipedia.org/wiki/Package_(OS_X)) of different resources. As such, if any localized files are found unnecessary, a new bundle is created without those files and replaces the original in the project. These new bundles are located at `Pods/Pruned Localized Bundles`

**Note:** No file is actually removed from your computer, only references to them in the project

