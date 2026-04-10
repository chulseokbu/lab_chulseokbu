# Backend

## 실행 방법

- **요구 사항**: Java 21
- **실행**

```bash
./gradlew bootRun
```

- **기본 주소**: `http://localhost:8080`

## 프론트(Flutter) 연결

`frontend/lib/api/api_config.dart`의 `ApiConfig.baseUrl`을 로컬 주소로 바꾸면 됩니다.

- **Android 에뮬레이터**: `http://10.0.2.2:8080`
- **iOS 시뮬레이터**: `http://localhost:8080`
- **실기기**: `http://<내-맥-로컬IP>:8080` (예: `http://192.168.0.10:8080`)

## 인증

- 로그인 성공 시 `accessToken`이 내려옵니다.
- 이후 요청은 헤더에 아래처럼 넣어주세요.

```
Authorization: Bearer <accessToken>
```

## 주요 API (프론트에서 사용)

- **회원가입**: `POST /lab/users/sign`
- **로그인**: `POST /lab/users/login`
- **체크인(입실)**: `POST /lab/attendance/in`
  - 성공 응답: `{ "success": true, "data": { "checkInId": <inoutId> } }`
- **체크아웃(퇴실)**: `POST /lab/attendance/out/{inoutId}`
- **최근 7일 기록**: `GET /lab/stay/week`
  - 각 항목: `{ "date": "YYYY-MM-DD", "checkIn": "HH:mm", "checkOut": "HH:mm" }`
- **최근 30일 체류시간**: `GET /lab/stay/month`
  - 각 항목: `{ "date": "YYYY-MM-DD", "duration": "3시간 45분", ... }`

## 모임(그룹) 기능 (추가)

모임 단위로 여러 구성원의 출석/체류를 조회하기 위한 API입니다.

- **내 모임 목록**: `GET /lab/meetings`
- **모임 생성(서버가 6자리 코드 생성)**: `POST /lab/meetings`
  - Request: `{ "name": "AI 연구실" }`
  - Response(data): `{ "id": 1, "code": "A1B2C3", "name": "...", "memberCount": 1, "createdAt": "YYYY-MM-DD" }`
- **모임 참여(코드 입력)**: `POST /lab/meetings/join`
  - Request: `{ "code": "A1B2C3" }`
- **모임 상세(참여자만)**: `GET /lab/meetings/{meetingId}`
  - 모임장에게만 응답에 `inviteCode`(실제로는 6자리 `code`와 동일) 포함
- **모임 탈퇴**: `POST /lab/meetings/{meetingId}/leave`
  - 모임장(생성자)이 나가면 가장 먼저 가입한 구성원이 다음 모임장, 남은 사람이 없으면 모임 삭제
- **모임 삭제(생성자만)**: `DELETE /lab/meetings/{meetingId}`
- **모임장 위임(생성자만)**: `POST /lab/meetings/{meetingId}/delegate`
  - Request: `{ "newLeaderMemberId": 2 }`
- **모임 잔류 현황(오늘)**: `GET /lab/meetings/{meetingId}/retention`
  - 각 항목: `{ "memberId": 1, "name": "Tom", "isPresent": true, "checkIn": "09:15", "lastExit": "YYYY-MM-DD HH:mm", "duration": "3시간 45분" }`
- **모임 최근 7일 체크인/체크아웃**: `GET /lab/meetings/{meetingId}/stay/week`
  - 각 항목: `{ "memberId": 1, "name": "Tom", "records": [ { "date":"YYYY-MM-DD", "checkIn":"HH:mm", "checkOut":"HH:mm" } ] }`
- **모임 최근 30일 체류시간**: `GET /lab/meetings/{meetingId}/stay/month`
  - 각 항목: `{ "memberId": 1, "name": "Tom", "records": [ { "date":"YYYY-MM-DD", "duration":"3시간 45분", ... } ] }`

## 참고

- Flutter Web을 위해 **CORS는 허용**하도록 설정되어 있습니다.
- **Railway 등 배포**: 이 저장소의 **`test` 브랜치** `backend/`를 빌드하면 위 모임·탈퇴 API가 포함됩니다. 배포 후 `/v3/api-docs`에서 `POST /lab/meetings/{meetingId}/leave` 존재 여부를 확인하면 됩니다.
