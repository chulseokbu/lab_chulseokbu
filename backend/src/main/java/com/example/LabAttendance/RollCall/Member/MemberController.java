package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Member.DTO.*;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateEmailException;
import com.example.LabAttendance.RollCall.global.Exception.MemberNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

@Tag(
        name = "Member",
        description = """
                회원 관리 API

                - 회원 가입
                - 로그인
                - 이메일 중복, 인증 실패 등의 예외를 처리합니다.
                """
)
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/users")
public class MemberController {

    private final MemberService memberService;

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
}
