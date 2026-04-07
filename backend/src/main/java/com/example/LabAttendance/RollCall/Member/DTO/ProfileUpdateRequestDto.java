package com.example.LabAttendance.RollCall.Member.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record ProfileUpdateRequestDto(

        @NotBlank(message = "닉네임은 필수 입력 값입니다.")
        String nickname,

        @NotBlank(message = "이메일은 필수 입력 값입니다.")
        @Email(message = "유효한 이메일 형식이 아닙니다.")
        String email,

        @NotBlank(message = "전화번호는 필수 입력 값입니다.")
        String phone
) {
}
