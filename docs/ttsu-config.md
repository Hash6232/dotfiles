# ッツ ttsu config

Configs for [ッツ ttsu](https://github.com/ttu-ttu/ebook-reader) online e-book reader.

## Local storage

JSON dump of the settings from the Local Storage

```json
{
  "disableWheelNavigation": "1",
  "trackerForwardSkipThreshold": "2700",
  "trackerPopupDetection": "0",
  "showExternalPlaceholder": "0",
  "autoReplication": "off",
  "trackerIdleTime": "0",
  "overwriteBookCompletion": "0",
  "theme": "light-theme",
  "startDayHoursForTracker": "0",
  "secondDimensionMaxValue": "800",
  "showCharacterCounter": "1",
  "fontFamilyGroupOne": "Noto Serif JP",
  "enableTextJustification": "0",
  "confirmClose": "0",
  "pauseTrackerOnCustomPointChange": "1",
  "hideSpoilerImage": "0",
  "adjustStatisticsAfterIdleTime": "1",
  "trackerAutoPause": "moderate",
  "hideFurigana": "0",
  "enableReaderWakeLock": "0",
  "lineHeight": "1.65",
  "cacheStorageData": "0",
  "keepLocalStatisticsOnDeletion": "1",
  "textMarginValue": "1",
  "selectionToBookmarkEnabled": "0",
  "statisticsMergeMode": "merge",
  "furiganaStyle": "partial",
  "statisticsEnabled": "0",
  "textMarginMode": "manual",
  "openTrackerOnCompletion": "1",
  "autoBookmark": "1",
  "customReadingPointEnabled": "0",
  "textIndentation": "2",
  "fontFamilyGroupTwo": "Noto Sans JP",
  "addCharactersOnCompletion": "0",
  "showPercentage": "1",
  "viewMode": "paginated",
  "autoBookmarkTime": "3",
  "prioritizeReaderStyles": "0",
  "writingMode": "horizontal-tb",
  "fontSize": "20",
  "replicationSaveBehavior": "new",
  "autoPositionOnResize": "1",
  "readingGoalsMergeMode": "merge",
  "enableTextWrapPretty": "0",
  "enableTapEdgeToFlip": "1",
  "pageColumns": "0",
  "firstDimensionMargin": "0",
  "trackerBackwardSkipThreshold": "2700",
  "avoidPageBreak": "0",
  "manualBookmark": "0",
  "hideSpoilerImageMode": "afterToc",
  "swipeThreshold": "10",
  "trackerSkipThresholdAction": "ignore",
  "trackerAutoStartTime": "0"
}
```

## User style

Tapping on the very edge of the screen to flip page is annoying so I increased the size of the buttons.

> [!TIP]
> `800px` is the max width of the page set in the settings.

```css
/* ==UserStyle==
@name           Responsive "Tap edge to flip" buttons
@namespace      github.com/openstyles/stylus
@version        1.0.0
@description    Increases size of "Tap edge to flip" buttons so they fill the entirety of the white space
@author         Hash6232
==/UserStyle== */

@-moz-document regexp("https://reader.ttsu.app/b.*") {
    button.left-0, button.right-0 {
        width: calc((100% - 800px)/2);
    }
}
```
