# 앱 아이콘 추가 가이드

## 1. 아이콘 이미지 준비

macOS 앱 아이콘은 다음 크기들이 필요합니다:

- `icon_16x16.png` (16x16 픽셀)
- `icon_16x16@2x.png` (32x32 픽셀)
- `icon_32x32.png` (32x32 픽셀)
- `icon_32x32@2x.png` (64x64 픽셀)
- `icon_128x128.png` (128x128 픽셀)
- `icon_128x128@2x.png` (256x256 픽셀)
- `icon_256x256.png` (256x256 픽셀)
- `icon_256x256@2x.png` (512x512 픽셀)
- `icon_512x512.png` (512x512 픽셀)
- `icon_512x512@2x.png` (1024x1024 픽셀)

## 2. 이미지 파일 추가 방법

### 방법 1: Xcode에서 직접 추가 (권장)

1. Xcode에서 프로젝트를 엽니다
2. 프로젝트 네비게이터에서 `Assets.xcassets` 폴더를 찾습니다
3. `AppIcon`을 클릭합니다
4. 각 슬롯에 해당하는 이미지를 드래그 앤 드롭합니다

### 방법 2: 파일 시스템에서 직접 추가

1. 다음 경로로 이동합니다:
   ```
   /Users/doyoung_kim/Documents/Git/dango/Assets.xcassets/AppIcon.appiconset/
   ```

2. 위에서 준비한 이미지 파일들을 이 폴더에 복사합니다

3. 파일 이름이 정확히 일치하는지 확인합니다:
   - `icon_16x16.png`
   - `icon_16x16@2x.png`
   - `icon_32x32.png`
   - `icon_32x32@2x.png`
   - `icon_128x128.png`
   - `icon_128x128@2x.png`
   - `icon_256x256.png`
   - `icon_256x256@2x.png`
   - `icon_512x512.png`
   - `icon_512x512@2x.png`

## 3. 아이콘 디자인 팁

- **간단하고 명확한 디자인**: 작은 크기에서도 알아볼 수 있어야 합니다
- **고해상도**: 모든 이미지는 PNG 형식으로 저장하고, 고해상도로 제작하세요
- **투명도**: macOS 아이콘은 투명 배경을 지원합니다
- **일관성**: 모든 크기에서 동일한 디자인이 보이도록 하세요

## 4. 아이콘 생성 도구

온라인 도구를 사용하여 한 번에 모든 크기를 생성할 수 있습니다:
- [App Icon Generator](https://www.appicon.co/)
- [IconKitchen](https://icon.kitchen/)
- [MakeAppIcon](https://makeappicon.com/)

## 5. 확인

이미지를 추가한 후:
1. Xcode에서 프로젝트를 빌드합니다
2. 앱을 실행하여 Dock이나 Finder에서 아이콘이 표시되는지 확인합니다

## 참고

현재 `Contents.json` 파일이 이미 설정되어 있으므로, 이미지 파일만 추가하면 됩니다.
