## 1.1.0

- Added ability to use inherited text style instead of fixed in the controller constructor
- Documentation improvements
- Code formatting improvements
- Suggestion callback API changed
- BREAKING: Added ability adding post create MentionEditingController suggestion callbacks
- BREAKING: Added ability to to do future request for idToMentionObject callback

### Migration Guide

This version introduces several breaking changes that will require you to change imports and callbacks.

#### onSuggestionChanged

`onSuggestionChanged` had a typo and is now fixed, furthermore `onSuggestionChanged` is now a final property. You cannot change it after creating the `MentionTextEditingController`. 

To add new callbacks after the creation, use `addSuggestionListener` and `removeSuggestionListener` on the controller instead.

Furthermore, the callback now uses `Function(MentionSuggestion)` instead of `Function(MentionSyntax?, String?)`.

#### idToMentionObject

`idToMentionObject` is now async. Wherever `idToMentionObject` was used, change the function to be async. 

#### Imports

The following classes are now in their own separate headers. To use them, just include their new headers.

- `MarkdownMentionSyntax`
- `MentionObject`
- `MentionSuggestion`
- `MentionSyntax`

## 1.0.7

- Fix issue where pasting text would invalidate mentions further down below

## 1.0.6

- Expose run text style
- Fix issue where deleting more than one character would not correctly detect if a mention should stop

## 1.0.5

- Fix issue where it wouldn't find mentions past the first position

## 1.0.4

- Fix issue where setting markup texts could cause an out of range exception

## 1.0.3

- Update README

## 1.0.2

- Update License
- Fix static analysis

## 1.0.1

- Add supported platforms list

## 1.0.0

- Initial release
