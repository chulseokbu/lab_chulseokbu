package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Member.DTO.AppleCompleteRequestDto;
import com.example.LabAttendance.RollCall.Member.DTO.AppleLoginRequestDto;
import com.example.LabAttendance.RollCall.Member.DTO.LoginResponseDto;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateEmailException;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateMemberNumException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Optional;

@Tag(name = "Apple Auth", description = "Sign in with Apple (서버 JWT 발급)")
@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/users/auth")
public class AppleAuthController {

    private final MemberService memberService;

    @Operation(summary = "Apple 로그인", description = "identityToken 검증 후 기존 연동 회원이면 로그인. 미가입이면 428 + needsProfile (404는 온보딩 분기에 쓰지 않음)")
    @PostMapping("/apple")
    public ResponseEntity<?> appleLogin(
            @Valid @RequestBody AppleLoginRequestDto body,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }
        try {
            Optional<LoginResponseDto> result = memberService.loginWithApple(body.identityToken());
            if (result.isPresent()) {
                return ResponseEntity.ok(result.get());
            }
            return ResponseEntity.status(HttpStatus.PRECONDITION_REQUIRED)
                    .body(Map.of("needsProfile", true));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }
    }

    @Operation(summary = "Apple 최초 가입(프로필 완료)", description = "토큰 재검증 후 회원 생성 및 JWT 발급")
    @PostMapping("/apple/complete")
    public ResponseEntity<?> appleComplete(
            @Valid @RequestBody AppleCompleteRequestDto body,
            BindingResult bindingResult
    ) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body(bindingResult.getFieldErrors());
        }
        try {
            LoginResponseDto dto = memberService.completeAppleProfile(body);
            return ResponseEntity.status(HttpStatus.CREATED).body(dto);
        } catch (DuplicateEmailException | DuplicateMemberNumException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }
    }
}
