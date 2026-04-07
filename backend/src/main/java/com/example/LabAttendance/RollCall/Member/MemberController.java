package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Member.DTO.*;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateEmailException;
import com.example.LabAttendance.RollCall.global.Exception.MemberNotFoundException;
import com.example.LabAttendance.RollCall.global.jwt.TokenBlacklistService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(
        name = "Member",
        description = """
                회원 관리 API

                - 회원 가입
                - 로그인
                - 로그아웃
                - 프로필 수정
                - 회원 탈퇴
                - 이메일 중복, 인증 실패 등의 예외를 처리합니다.
                """
)
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/users")
public class MemberController {

    private final MemberService memberService;
    private final TokenBlacklistService tokenBlacklistService;

    @Operation(
            summary = "회원 가입",
            description = """
                    신규 사용자를 회원으로 등록합니다.

                    ### 처리 흐름
                    1. 요청 바디(MemberSignupRequestDto)의 유효성을 검증합니다.
                    2. 이메일 중복 여부를 확인합니다.
                    3. 회원 정보를 저장하고 생성된 회원 정보를 반환합니다.

                    ### 실패 조건
                    - 입력값 검증 실패 (400)
                    - 이메일 중복 (409)
                    """,
            responses = {
                    @ApiResponse(
                            responseCode = "201",
                            description = "회원 가입 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = MemberResponseDto.class),
                                    examples = @ExampleObject(
                                            name = "signup-success",
                                            summary = "회원 가입 성공",
                                            value = """
                                                    {
                                                      "id": 1,
                                                      "email": "test@test.com",
                                                      "name": "홍길동"
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "400",
                            description = "입력값 검증 실패",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "validation-error",
                                            summary = "Validation Error",
                                            value = """
                                                    [
                                                      {
                                                        "field": "email",
                                                        "defaultMessage": "이메일 형식이 올바르지 않습니다."
                                                      }
                                                    ]
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "409",
                            description = "이메일 중복",
                            content = @Content(
                                    mediaType = "text/plain",
                                    examples = @ExampleObject(
                                            name = "duplicate-email",
                                            summary = "이메일 중복",
                                            value = "이미 사용 중인 이메일입니다."
                                    )
                            )
                    )
            }
    )
    @PostMapping("/sign")
    public ResponseEntity<?> signup(
            @Valid @RequestBody MemberSignupRequestDto requestDto,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }

        MemberResponseDto responseDto;
        try {
            responseDto = memberService.create(requestDto);
        } catch (DuplicateEmailException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    }

    @Operation(
            summary = "로그인",
            description = """
                    사용자의 이메일과 비밀번호로 로그인을 수행합니다.

                    ### 처리 흐름
                    1. 이메일 / 비밀번호 유효성 검증
                    2. 사용자 인증
                    3. 인증 성공 시 로그인 응답 정보 반환

                    ### 실패 조건
                    - 이메일 또는 비밀번호 불일치 (401)
                    - 입력값 검증 실패 (400)
                    """,
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "로그인 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = LoginResponseDto.class),
                                    examples = @ExampleObject(
                                            name = "login-success",
                                            summary = "로그인 성공",
                                            value = """
                                                    {
                                                      "memberId": 1,
                                                      "email": "test@test.com",
                                                      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "400",
                            description = "입력값 검증 실패",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "validation-error",
                                            summary = "Validation Error",
                                            value = """
                                                    [
                                                      {
                                                        "field": "password",
                                                        "defaultMessage": "비밀번호는 필수 입력값입니다."
                                                      }
                                                    ]
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "401",
                            description = "인증 실패",
                            content = @Content(
                                    mediaType = "text/plain",
                                    examples = @ExampleObject(
                                            name = "login-fail",
                                            summary = "로그인 실패",
                                            value = "이메일 또는 비밀번호가 일치하지 않습니다."
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "500",
                            description = "서버 오류",
                            content = @Content(
                                    mediaType = "text/plain",
                                    examples = @ExampleObject(
                                            name = "server-error",
                                            summary = "서버 오류",
                                            value = "서버 오류 발생"
                                    )
                            )
                    )
            }
    )
    @PostMapping("/login")
    public ResponseEntity<?> login(
            @Valid @RequestBody LoginRequestDto loginRequestDto,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }

        LoginResponseDto responseDto;

        try {
            responseDto = memberService.login(loginRequestDto);
        } catch (MemberNotFoundException | BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body("이메일 또는 비밀번호가 일치하지 않습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("서버 오류 발생: " + e.getMessage());
        }

        return ResponseEntity.ok(responseDto);
    }

    @Operation(
            summary = "로그아웃",
            description = """
                    현재 로그인된 사용자를 로그아웃 처리합니다.

                    ### 처리 흐름
                    1. Authorization 헤더에서 JWT 토큰을 추출합니다.
                    2. 해당 토큰을 블랙리스트에 등록하여 재사용을 차단합니다.

                    ### 요청 헤더
                    - `Authorization: Bearer {token}`
                    """,
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "로그아웃 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "logout-success",
                                            summary = "로그아웃 성공",
                                            value = """
                                                    {
                                                      "message": "로그아웃 되었습니다."
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "403",
                            description = "인증 토큰 없음 또는 만료",
                            content = @Content(mediaType = "application/json")
                    )
            }
    )
    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpServletRequest request) {
        String token = resolveToken(request);
        if (token != null) {
            tokenBlacklistService.blacklist(token);
        }
        return ResponseEntity.ok(Map.of("message", "로그아웃 되었습니다."));
    }

    @Operation(
            summary = "프로필 수정",
            description = """
                    로그인한 사용자의 프로필 정보(닉네임, 이메일, 전화번호)를 수정합니다.

                    ### 변경 가능 필드
                    - 닉네임
                    - 이메일
                    - 전화번호

                    ### 요청 헤더
                    - `Authorization: Bearer {token}`
                    """,
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "수정 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = MemberProfileResponseDto.class),
                                    examples = @ExampleObject(
                                            name = "profile-update-success",
                                            summary = "프로필 수정 성공",
                                            value = """
                                                    {
                                                      "id": 1,
                                                      "memberId": 20250001,
                                                      "nickname": "Tom",
                                                      "email": "tom@test.com",
                                                      "phone": "01012345678"
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "400",
                            description = "입력값 검증 실패",
                            content = @Content(mediaType = "application/json")
                    ),
                    @ApiResponse(
                            responseCode = "403",
                            description = "인증 토큰 없음 또는 만료",
                            content = @Content(mediaType = "application/json")
                    ),
                    @ApiResponse(
                            responseCode = "404",
                            description = "회원을 찾을 수 없음",
                            content = @Content(mediaType = "application/json")
                    ),
                    @ApiResponse(
                            responseCode = "409",
                            description = "이메일 중복",
                            content = @Content(
                                    mediaType = "text/plain",
                                    examples = @ExampleObject(
                                            name = "duplicate-email",
                                            value = "이미 존재하는 이메일입니다: new@test.com"
                                    )
                            )
                    )
            }
    )
    @PatchMapping("/profile")
    public ResponseEntity<?> updateProfile(
            @Valid @RequestBody ProfileUpdateRequestDto requestDto,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }

        Long memberId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        try {
            MemberProfileResponseDto responseDto = memberService.updateProfile(memberId, requestDto);
            return ResponseEntity.ok(responseDto);
        } catch (MemberNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (DuplicateEmailException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        }
    }

    @Operation(
            summary = "회원 탈퇴",
            description = """
                    현재 로그인된 사용자의 계정을 삭제합니다.

                    ### 처리 흐름
                    1. JWT 토큰에서 회원 ID를 추출합니다.
                    2. 해당 회원이 참여한 모임 정보를 정리합니다.
                    3. 회원 정보 및 관련 데이터(출석 기록 등)를 삭제합니다.
                    4. 사용 중이던 토큰을 블랙리스트에 등록합니다.

                    ### 요청 헤더
                    - `Authorization: Bearer {token}`
                    """,
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "회원 탈퇴 성공",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "withdraw-success",
                                            summary = "회원 탈퇴 성공",
                                            value = """
                                                    {
                                                      "message": "회원 탈퇴가 완료되었습니다."
                                                    }
                                                    """
                                    )
                            )
                    ),
                    @ApiResponse(
                            responseCode = "403",
                            description = "인증 토큰 없음 또는 만료",
                            content = @Content(mediaType = "application/json")
                    ),
                    @ApiResponse(
                            responseCode = "404",
                            description = "회원을 찾을 수 없음",
                            content = @Content(
                                    mediaType = "text/plain",
                                    examples = @ExampleObject(
                                            name = "member-not-found",
                                            summary = "회원 없음",
                                            value = "존재하지 않는 회원입니다."
                                    )
                            )
                    )
            }
    )
    @DeleteMapping("/withdraw")
    public ResponseEntity<?> withdraw(HttpServletRequest request) {
        Long memberId = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        try {
            memberService.withdraw(memberId);
        } catch (MemberNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }

        String token = resolveToken(request);
        if (token != null) {
            tokenBlacklistService.blacklist(token);
        }

        return ResponseEntity.ok(Map.of("message", "회원 탈퇴가 완료되었습니다."));
    }

    private String resolveToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }
}
