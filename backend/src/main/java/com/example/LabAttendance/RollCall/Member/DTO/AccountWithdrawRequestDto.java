package com.example.LabAttendance.RollCall.Member.DTO;

import jakarta.validation.constraints.NotBlank;

public record AccountWithdrawRequestDto(
        @NotBlank(message = "비밀번호는 필수입니다.")
        String password
) {
}
