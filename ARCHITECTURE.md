# Dango 아키텍처 가이드

## Clean Architecture 개요

Dango는 Clean Architecture 원칙을 따라 3개의 주요 레이어로 구성됩니다:

1. **Domain Layer**: 비즈니스 로직과 엔티티 (의존성 없음)
2. **Data Layer**: 데이터 소스 구현 (CoreData, Network 등)
3. **Presentation Layer**: UI (SwiftUI Views + ViewModels)

## 레이어별 상세 설명

### Domain Layer

#### Entities
- `Word`: 단어 엔티티 (jpText, reading, meanings, examples 등)
- `Meaning`: 뜻 엔티티
- `Example`: 예문 엔티티
- `Tag`: 태그 엔티티
- `ReviewLog`: 복습 로그 엔티티

#### Repository Protocols
- `WordRepository`: 단어 CRUD 및 검색
- `ReviewLogRepository`: 복습 로그 관리
- `TagRepository`: 태그 관리
- `DictionaryProvider`: 사전 검색 (자동 채움)

#### UseCases
각 UseCase는 단일 책임을 가집니다:
- `AddWordUseCase`: 단어 추가 (중복 정책 포함)
- `UpdateWordUseCase`: 단어 업데이트
- `DeleteWordUseCase`: Soft Delete
- `RestoreWordUseCase`: 복원
- `PermanentlyDeleteWordUseCase`: 영구 삭제
- `SearchWordsUseCase`: 검색
- `FetchWordsUseCase`: 전체 조회
- `ToggleFavoriteUseCase`: 즐겨찾기 토글
- `FetchDueReviewsUseCase`: 복습 대상 조회
- `SubmitReviewUseCase`: 복습 제출 (SRS 계산)
- `AutofillWordUseCase`: 자동 채움
- `CSVImportUseCase`: CSV 가져오기
- `CSVExportUseCase`: CSV 내보내기

### Data Layer

#### Persistence
- `PersistenceController`: CoreData + CloudKit 설정 및 관리
- `WordMapper`: Domain Entity <-> CoreData ManagedObject 변환
- CoreData 스키마: `DangoModel.xcdatamodeld`

#### Repositories
- `CoreDataWordRepository`: WordRepository 구현
- `CoreDataReviewLogRepository`: ReviewLogRepository 구현
- `CoreDataTagRepository`: TagRepository 구현

#### Providers
- `MockDictionaryProvider`: Mock 사전 Provider (데모용)
- `DictionaryCache`: 캐싱 레이어 (TTL 30일)

### Presentation Layer

#### ViewModels
- `WordListViewModel`: 단어 목록 상태 관리
- `WordDetailViewModel`: 단어 상세 상태 관리
- `WordEditorViewModel`: 단어 편집 + 자동 채움
- `ReviewViewModel`: 복습 세션 관리

#### Views
- `ContentView`: 메인 3컬럼 레이아웃 (NavigationSplitView)
- `SidebarView`: 사이드바 (오늘 복습, 전체 단어, 태그 등)
- `WordListView`: 단어 목록 + 검색/필터
- `WordDetailView`: 단어 상세 정보
- `WordEditorView`: 단어 편집 (자동 채움 패널 포함)
- `ReviewSessionView`: 복습 세션 (카드 UI)
- `SettingsView`: 설정 (iCloud 상태, Import/Export)

#### Components
- `VisualEffectBlur`: Glassmorphism 효과 컴포넌트

## 의존성 주입 (DI)

### DIContainer
`App/DIContainer.swift`에서 모든 의존성을 조립합니다:

```swift
// 1. Persistence 생성
persistenceController = PersistenceController()

// 2. Providers 생성 (실데이터 + 오프라인 fallback)
dictionaryProvider = JishoDictionaryProvider(
    http: URLSessionHTTPClient(),
    cache: dictionaryCache,
    fallback: MockDictionaryProvider(cache: dictionaryCache)
)

// 3. Repositories 생성
wordRepository = CoreDataWordRepository(persistenceController: persistenceController)

// 4. UseCases 생성
addWordUseCase = AddWordUseCaseImpl(wordRepository: wordRepository)

// 5. ViewModels 생성 (lazy)
wordListViewModel = WordListViewModel(...)
```

### 테스트에서 DI
테스트에서는 Mock Repository를 사용:

```swift
let mockRepository = MockWordRepository()
let useCase = AddWordUseCaseImpl(wordRepository: mockRepository)
```

## 동시성 (Concurrency)

### async/await 사용
- 모든 Repository 메서드는 `async throws`
- UseCase도 `async throws`
- ViewModel에서 `Task { }` 사용

### MainActor
- ViewModel은 `@MainActor`로 표시
- UI 업데이트는 자동으로 Main Thread에서 실행

## 테스트 전략

### Unit Tests
- Domain UseCase 테스트 (Mock Repository)
- Repository 구현 테스트 (In-Memory CoreData)

### 예시 테스트
1. `AddWordUseCaseTests`: 중복 정책 테스트
2. `SubmitReviewUseCaseTests`: SRS 계산 검증
3. `AutofillWordUseCaseTests`: Mock Provider 결과 반영

## 확장 가이드

### 실제 사전 API 추가
1. `DictionaryProvider` 프로토콜 구현
2. `DIContainer`에서 교체:
```swift
dictionaryProvider = NaverDictionaryProvider() // 또는 JishoDictionaryProvider
```

### 새로운 UseCase 추가
1. Domain/UseCases에 프로토콜 + 구현체 추가
2. DIContainer에 등록
3. ViewModel에서 사용

### 새로운 화면 추가
1. Presentation/Views에 View 추가
2. 필요시 ViewModel 추가
3. ContentView에서 라우팅

## 주의사항

1. **Domain은 순수 Swift**: Apple 프레임워크 의존 금지
2. **Repository는 Protocol**: 구현체 교체 가능해야 함
3. **ViewModel은 MainActor**: UI 업데이트 보장
4. **Mapper 사용**: Domain Entity와 CoreData 분리
5. **에러 처리**: Domain 수준에서 정의, Presentation에서 사용자 메시지로 변환
