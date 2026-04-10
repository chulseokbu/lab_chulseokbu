package com.example.LabAttendance.RollCall.Member.DTO;

import com.example.LabAttendance.RollCall.global.Gender;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AppleCompleteRequestDto(
        @NotBlank(message = "identityToken은 필수입니다.")
        String identityToken,
        String authorizationCode,
        String userIdentifier,
        @NotNull(message = "학번은 필수입니다.")
        Long memberId,
        @NotBlank(message = "닉네임은 필수입니다.")
        String nickname,
        @NotBlank(message = "이메일은 필수입니다.")
        @Email(message = "유효한 이메일 형식이 아닙니다.")
        String email,
        @NotBlank(message = "전화번호는 필수입니다.")
        String phone,
        @NotNull(message = "성별은 필수입니다.")
        Gender gender
) {}
