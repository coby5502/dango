# Dango 프로젝트 빠른 시작 가이드

## 프로젝트 열기

1. Xcode 실행
2. `File` > `Open...`
3. `/Users/doyoung_kim/Documents/Git/dango/Dango.xcodeproj` 선택
4. `Open` 클릭

## 첫 빌드 전 확인사항

### 1. CoreData 모델 확인
- `Data/Persistence/DangoModel.xcdatamodeld` 파일이 프로젝트에 포함되어 있는지 확인
- Xcode에서 파일을 열어 엔티티가 올바르게 설정되었는지 확인

### 2. CloudKit 설정
1. 프로젝트 네비게이터에서 프로젝트 선택
2. **Target** > **Dango** 선택
3. **Signing & Capabilities** 탭
4. **+ Capability** 클릭하여 **CloudKit** 추가
5. Container Identifier: `iCloud.com.dango.app`

### 3. Entitlements 파일
- `Dango.entitlements` 파일이 프로젝트 루트에 있는지 확인
- Build Settings에서 경로가 올바른지 확인

## 빌드 및 실행

1. `Cmd + B`로 빌드
2. 오류가 발생하면:
   - Clean Build Folder (`Cmd + Shift + K`)
   - 다시 빌드
3. `Cmd + R`로 실행

## 알려진 문제 해결

### "Cannot find type 'WordEntity'"
- CoreData 모델 파일이 프로젝트에 포함되어 있는지 확인
- Codegen 설정 확인 (Data Model Inspector에서)

### "CloudKit container not found"
- Capabilities에서 CloudKit 활성화 확인
- Container Identifier 확인

### Import 오류
- 파일이 올바른 Target에 포함되어 있는지 확인
- File Inspector에서 Target Membership 확인

## 다음 단계

프로젝트가 성공적으로 빌드되면:
1. CoreData 모델에서 엔티티 생성 확인
2. CloudKit Dashboard에서 스키마 배포
3. 앱 실행 및 테스트
