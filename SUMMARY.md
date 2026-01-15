# Dango 프로젝트 요약

## 완성된 기능

### ✅ 아키텍처
- Clean Architecture 레이어 분리 (Domain, Data, Presentation, App)
- SOLID 원칙 준수
- DI Container 구현
- Protocol 기반 의존성 역전

### ✅ Domain Layer
- **Entities**: Word, Meaning, Example, Tag, ReviewLog
- **Repository Protocols**: WordRepository, ReviewLogRepository, TagRepository, DictionaryProvider
- **UseCases**: 
  - AddWordUseCase (중복 정책 포함)
  - UpdateWordUseCase
  - DeleteWordUseCase (Soft Delete)
  - RestoreWordUseCase
  - PermanentlyDeleteWordUseCase
  - SearchWordsUseCase
  - FetchWordsUseCase
  - ToggleFavoriteUseCase
  - FetchDueReviewsUseCase
  - SubmitReviewUseCase (SRS 계산)
  - AutofillWordUseCase
  - CSVImportUseCase
  - CSVExportUseCase

### ✅ Data Layer
- **PersistenceController**: CoreData + NSPersistentCloudKitContainer
- **CoreData 스키마**: WordEntity, MeaningEntity, ExampleEntity, TagEntity, ReviewLogEntity
- **Repository 구현**: CoreDataWordRepository, CoreDataReviewLogRepository, CoreDataTagRepository
- **Mapper**: WordMapper, TagMapper, ReviewLogMapper
- **Dictionary Provider**: MockDictionaryProvider (실제 API로 교체 가능)
- **Cache**: DictionaryCache (TTL 30일)

### ✅ Presentation Layer
- **ViewModels**: WordListViewModel, WordDetailViewModel, WordEditorViewModel, ReviewViewModel
- **Views**:
  - ContentView (3컬럼 NavigationSplitView)
  - SidebarView
  - WordListView (검색/필터/정렬)
  - WordDetailView
  - WordEditorView (자동 채움 패널 포함)
  - ReviewSessionView (카드 UI, SRS 평가)
  - SettingsView (iCloud 상태, Import/Export)
  - TrashView
- **Components**: VisualEffectBlur (Glassmorphism)

### ✅ 테스트
- AddWordUseCaseTests (중복 정책 테스트)
- SubmitReviewUseCaseTests (SRS 계산 검증)
- AutofillWordUseCaseTests (Mock Provider 테스트)

## 주요 특징

### 1. 자동 채움 (Autofill)
- jpText 입력 시 0.4초 디바운스 후 자동 검색
- MockDictionaryProvider로 데모 (실제 API로 교체 가능)
- 캐싱 레이어 (TTL 30일)
- UX 블로킹 없음 (비동기 처리)

### 2. SRS 복습 시스템
- 간단한 SRS 알고리즘 구현
- 4단계 평가: 다시/어려움/보통/쉬움
- nextReviewAt, srsLevel, easeFactor 자동 계산
- ReviewLog 기록

### 3. iCloud 동기화
- NSPersistentCloudKitContainer 사용
- 동기화 상태 모니터링 (synced/syncing/offline/needSignIn/error)
- 충돌 최소화 (updatedAt 갱신, soft delete)
- Offline-first (로컬 우선)

### 4. Glassmorphism UI
- NSVisualEffectView 기반
- Sidebar, List, Detail 배경에 적용
- macOS 네이티브 느낌

### 5. Import/Export
- CSV 형식 지원
- 중복 정책 적용
- NSOpenPanel/NSSavePanel 사용

## 프로젝트 구조

```
Dango/
├── App/                    # DI Container + App Entry
├── Domain/                 # 비즈니스 로직 (의존성 없음)
│   ├── Entities/
│   ├── Repositories/
│   └── UseCases/
├── Data/                   # 데이터 계층
│   ├── Persistence/
│   ├── Repositories/
│   └── Providers/
├── Presentation/          # UI 계층
│   ├── Components/
│   ├── ViewModels/
│   └── Views/
└── Tests/                 # 테스트
    └── DomainTests/
```

## 다음 단계 (확장 가능)

1. **실제 사전 API 연동**
   - MockDictionaryProvider를 NaverDictionaryProvider 또는 JishoDictionaryProvider로 교체
   - DictionaryProvider 프로토콜만 구현하면 됨

2. **추가 기능**
   - 통계 화면 (복습 진행률, 단어 수 등)
   - 태그 관리 화면
   - JSON 백업/복원
   - 다크 모드 지원 강화

3. **성능 최적화**
   - 대량 데이터 처리 최적화
   - 이미지 캐싱 (예문 이미지 등)
   - 검색 인덱싱

4. **테스트 확장**
   - Integration Tests
   - UI Tests
   - Performance Tests

## 컴파일 주의사항

1. **CoreData 엔티티 클래스**
   - Xcode에서 CoreData 모델 편집기 열기
   - 각 엔티티의 Codegen 설정 확인

2. **CloudKit 설정**
   - Capabilities에서 CloudKit 활성화
   - Container Identifier: `iCloud.com.dango.app`

3. **Import 문**
   - 일부 파일에서 `@testable import Domain` 등 필요할 수 있음
   - 실제 프로젝트 구조에 맞게 조정

## 코드 품질

- ✅ SOLID 원칙 준수
- ✅ Clean Architecture 준수
- ✅ Protocol 기반 설계
- ✅ async/await 사용
- ✅ MainActor 보장
- ✅ 에러 처리
- ✅ 테스트 가능한 구조

## 문서

- `PROJECT_STRUCTURE.md`: 프로젝트 구조 상세 설명
- `ARCHITECTURE.md`: 아키텍처 가이드
- `BUILD_INSTRUCTIONS.md`: 빌드 가이드
- `README.md`: 프로젝트 개요
