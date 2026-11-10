# App Store capture workflow

The delivered pack is `output/app-store/`; `output/Harta-App-Store-Assets.zip` is the portable bundle. These generated assets are ignored by Git. Listing-copy source is `Configuration/AppStore/en-US.json`.

Create dedicated simulators named `Harta App Store …` for iPhone 17 Pro, iPhone 17 Pro Max, and iPad Pro 13-inch. Use the iOS 26 runtime. With the simulator app built:

```sh
python3 scripts/app-store-assets/prepare.py SIMULATOR_UUID .build/DerivedData/Build/Products/Debug-iphonesimulator/Harta.app
RUN_APP_STORE_SCREENSHOTS=1 xcodebuild -project Harta.xcodeproj -scheme Harta \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -derivedDataPath .build/DerivedData -resultBundlePath .build/CAPTURE_NAME.xcresult \
  CODE_SIGNING_ALLOWED=NO -only-testing:HartaUITests/AppStoreScreenshotTests test
xcrun xcresulttool export attachments --path .build/CAPTURE_NAME.xcresult \
  --output-path output/app-store/capture-medium
```

Use `capture-medium`, `capture-large-final`, and `capture-ipad-retry` as the attachment export directories expected by `package.py`. Run captures sequentially and refresh simulated location shortly before each run. Live map tiles can load slowly on a freshly booted simulator; inspect each image and repeat any capture with blank tiles. The iPad set uses four scenes; the iPhone sets add the optional layers sheet.

`python3 scripts/app-store-assets/package.py` validates dimensions and PNG colour type, copies original screenshots with meaningful names, generates the HTML review gallery and SHA-256 manifest, and creates the ZIP. Existing brand/copy/README assets in `output/app-store` are included. It never changes screenshot pixels.
