# Dango 빌드 가이드

## 요구사항

- macOS 26 (또는 호환 버전)
- Xcode 26 (또는 호환 버전)
- Swift 6.0+

## 프로젝트 설정

### 1. Xcode 프로젝트 생성

1. Xcode에서 새 프로젝트 생성
2. macOS App 템플릿 선택
3. SwiftUI 사용
4. Core Data 포함

### 2. 파일 구조 설정

생성된 파일들을 다음 구조로 이동:

```
Dango/
├── App/
├── Domain/
├── Data/
├── Presentation/
└── Tests/
```

### 3. CoreData 모델 설정

1. `DangoModel.xcdatamodeld` 파일 생성
2. 엔티티 추가:
   - WordEntity
   - MeaningEntity
   - ExampleEntity
   - TagEntity
   - ReviewLogEntity

3. 속성 및 관계 설정 (자세한 내용은 `DangoModel.xcdatamodeld/contents` 참조)

### 4. CloudKit 설정

1. Xcode 프로젝트 설정에서 Capabilities 탭
2. CloudKit 활성화
3. Container Identifier: `iCloud.com.dango.app`

### 5. Info.plist 설정

필요한 권한 추가:
- 네트워크 접근 (사전 API 사용 시)

## 빌드 및 실행

### 개발 빌드
```bash
xcodebuild -scheme Dango -configuration Debug
```

### 릴리즈 빌드
```bash
xcodebuild -scheme Dango -configuration Release
```

## 테스트 실행

```bash
xcodebuild test -scheme Dango
```

또는 Xcode에서 `Cmd+U`

## 알려진 이슈 및 해결

### CoreData 엔티티 클래스 자동 생성
- Xcode에서 CoreData 모델 편집기 열기
- 각 엔티티의 Codegen을 "Class Definition" 또는 "Category/Extension"으로 설정

### CloudKit 동기화 문제
- iCloud 계정 로그인 확인
- Container Identifier 확인
- 개발 환경에서는 CloudKit Dashboard에서 스키마 배포 필요

### Glassmorphism 효과가 보이지 않음
- macOS 버전 확인 (macOS 11+ 필요)
- NSVisualEffectView.Material 확인

## 다음 단계

1. 실제 사전 API Provider 구현 (MockDictionaryProvider 교체)
2. CSV Import/Export 완전 구현
3. 통계 화면 추가
4. 백업/복원 기능 추가
