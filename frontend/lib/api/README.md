# API 연동 가이드

Swagger: https://labchulseokbu-production.up.railway.app/swagger-ui/index.html

## 구조

- `api_config.dart` - Base URL, 엔드포인트 상수
- `models/` - 요청/응답 DTO
- `services/` - API 호출 서비스 (Auth, Attendance, LabStay)

## 서버 연결 시 작업

1. `lib/config/app_config.dart`에서 `useMockData = false`로 변경
2. 로그인/회원가입 화면에서 `AuthService.instance.login()`, `signup()` 호출
3. 랩실 상태(들어오기/나가기)에서 `AttendanceService.instance.checkIn()`, `checkOut()` 호출
4. 잔류현황 등에서 `LabStayService.instance.getLast7Days()`, `getLast30Days()` 호출

## API 목록

| 기능 | 메서드 | 엔드포인트 |
|------|--------|------------|
| 회원가입 | POST | /lab/users/sign |
| 로그인 | POST | /lab/users/login |
| 체크인 | POST | /lab/attendance/in |
| 체크아웃 | POST | /lab/attendance/out/{inout_id} |
| 7일 체류 | GET | /lab/stay/week |
| 30일 체류 | GET | /lab/stay/month |
