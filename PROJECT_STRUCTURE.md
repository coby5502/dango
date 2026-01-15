# Dango 프로젝트 구조

## Clean Architecture 레이어 구조

```
Dango/
├── App/                          # Composition Root (DI Container)
│   ├── DIContainer.swift         # 의존성 주입 컨테이너
│   └── DangoApp.swift            # App Entry Point
│
├── Domain/                       # 비즈니스 로직 레이어 (의존성 없음)
│   ├── Entities/
│   │   └── Word.swift            # Word, Meaning, Example, Tag, ReviewLog 엔티티
│   ├── Repositories/
│   │   ├── WordRepository.swift  # Repository 프로토콜
│   │   └── DictionaryRepository.swift
│   └── UseCases/
│       ├── AddWordUseCase.swift
│       ├── UpdateWordUseCase.swift
│       ├── DeleteWordUseCase.swift
│       ├── SearchWordsUseCase.swift
│       ├── ReviewUseCase.swift
│       ├── AutofillWordUseCase.swift
│       └── ImportExportUseCase.swift
│
├── Data/                         # 데이터 계층
│   ├── Persistence/
│   │   ├── PersistenceController.swift    # CoreData + CloudKit 설정
│   │   ├── DangoModel.xcdatamodeld/        # CoreData 스키마
│   │   └── Mappers/
│   │       └── WordMapper.swift            # Entity <-> ManagedObject 변환
│   ├── Repositories/
│   │   ├── CoreDataWordRepository.swift
│   │   ├── CoreDataReviewLogRepository.swift
│   │   └── CoreDataTagRepository.swift
│   └── Providers/
│       └── MockDictionaryProvider.swift   # 사전 Provider (Mock)
│
├── Presentation/                 # UI 계층
│   ├── Components/
│   │   └── VisualEffectBlur.swift         # Glassmorphism 컴포넌트
│   ├── ViewModels/
│   │   ├── WordListViewModel.swift
│   │   ├── WordDetailViewModel.swift
│   │   ├── WordEditorViewModel.swift
│   │   └── ReviewViewModel.swift
│   └── Views/
│       ├── ContentView.swift              # 메인 3컬럼 레이아웃
│       ├── SidebarView.swift
│       ├── WordListView.swift
│       ├── WordDetailView.swift
│       ├── WordEditorView.swift
│       ├── ReviewSessionView.swift
│       └── SettingsView.swift
│
└── Tests/                        # 테스트
    └── DomainTests/
        ├── AddWordUseCaseTests.swift
        ├── SubmitReviewUseCaseTests.swift
        └── AutofillWordUseCaseTests.swift
```

## 아키텍처 원칙

### 1. 의존성 방향
- **Domain**: 어떤 외부 의존성도 없음 (순수 Swift)
- **Data**: Domain 프로토콜 구현
- **Presentation**: Domain UseCase에만 의존
- **App**: 모든 레이어를 조립 (Composition Root)

### 2. SOLID 원칙
- **S (Single Responsibility)**: 각 UseCase는 단일 책임
- **O (Open/Closed)**: Protocol 기반 확장 가능
- **L (Liskov Substitution)**: Repository 구현체 교체 가능
- **I (Interface Segregation)**: 작은 프로토콜로 분리
- **D (Dependency Inversion)**: 추상화(Protocol)에 의존

### 3. DI (의존성 주입)
- `DIContainer`에서 모든 의존성 조립
- ViewModel은 생성자 주입
- 테스트에서 Mock으로 교체 가능

## 주요 컴포넌트

### PersistenceController
- CoreData + NSPersistentCloudKitContainer 설정
- iCloud 동기화 상태 모니터링
- Background Context 관리

### Repository 패턴
- Domain 프로토콜 정의
- Data 계층에서 CoreData로 구현
- Mapper를 통한 Entity 변환

### UseCase 패턴
- 비즈니스 로직 캡슐화
- 단일 책임 원칙 준수
- 테스트 용이성

### ViewModel
- UI 상태 관리
- UseCase 조합
- MainActor 보장

## 확장 포인트

### Dictionary Provider 교체
```swift
// MockDictionaryProvider를 실제 API Provider로 교체
// 예: NaverDictionaryProvider, JishoDictionaryProvider
```

### 추가 UseCase
- `FetchWordByIdUseCase`
- `BulkDeleteWordsUseCase`
- `ExportToJSONUseCase`

### 추가 화면
- `TagManagementView`
- `StatisticsView`
- `BackupRestoreView`

## 테스트 전략

### Unit Tests
- Domain UseCase 테스트 (Mock Repository 사용)
- Repository 구현 테스트 (In-Memory CoreData)

### Integration Tests
- UseCase + Repository 통합 테스트
- ViewModel + UseCase 통합 테스트

### UI Tests
- 주요 사용자 플로우 테스트
