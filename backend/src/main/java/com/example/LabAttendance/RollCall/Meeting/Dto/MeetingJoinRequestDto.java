package com.example.LabAttendance.RollCall.Meeting.Dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record MeetingJoinRequestDto(
        @NotBlank(message = "모임 코드는 필수 입력 값입니다.")
        @Pattern(regexp = "^[A-Za-z0-9]{6}$", message = "모임 코드는 6자리 영문/숫자 조합이어야 합니다.")
        String code
) {
}

