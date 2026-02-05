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

## 참고

- Flutter Web을 위해 **CORS는 허용**하도록 설정되어 있습니다.
