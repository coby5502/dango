# Dango - 일본어 단어장 앱

macOS 26 SwiftUI 앱으로 구현된 일본어 단어장(업무용) 애플리케이션입니다.

## 아키텍처

Clean Architecture + SOLID 원칙을 준수하여 설계되었습니다.

### 레이어 구조

```
Dango/
├── App/                    # Composition Root (DI Container)
├── Domain/                 # 비즈니스 로직 (의존성 없음)
│   ├── Entities/
│   ├── Repositories/
│   └── UseCases/
├── Data/                   # 데이터 계층
│   ├── Persistence/
│   ├── Repositories/
│   └── Providers/
└── Presentation/           # UI 계층
    ├── ViewModels/
    └── Views/
```

## 주요 기능

- 단어 CRUD (생성, 읽기, 업데이트, 삭제)
- 검색 및 필터링
- SRS(Spaced Repetition System) 복습 시스템
- 사전 자동 채움
- iCloud 동기화 (Core Data + CloudKit)
- CSV Import/Export
- Glassmorphism UI

## 기술 스택

- macOS 26
- SwiftUI
- Core Data + NSPersistentCloudKitContainer
- async/await
- Clean Architecture
- SOLID 원칙
