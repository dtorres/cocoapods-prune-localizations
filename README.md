# Prune Localizations

This plugin allows you to remove unused localizations provided by the Pods you depend on.

## Installation

    $ gem install cocoapods-prune-localizations

## Usage

In your Podfile, add this line:

    plugin 'cocoapods-prune-localizations', {:localizations => ["en.lproj", "es.lproj"]}

This will keep the English and Spanish localizations in the Pods. Modify the localizations to your needs.
