package com.example.LabAttendance.RollCall.Member.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;


public record MemberSignupRequestDto(

        @NotNull(message = "학번은 필수 입력 값입니다.")
        Long memberId,

        @NotBlank(message = "닉네임은 필수 입력 값입니다.")
        String nickname,

        @NotBlank(message = "비밀번호는 필수 입력 값입니다.")
        @Size(min = 8, max = 20, message = "비밀번호는 8자 이상 20자 이하여야 합니다.")
        String password,

        @NotBlank(message = "이메일은 필수 입력 값입니다.")
        @Email(message = "유효한 이메일 형식이 아닙니다.")
        String email,

        @NotBlank(message = "전화번호는 필수 입력 값입니다.")
        String phone
){

}