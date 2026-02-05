package com.example.LabAttendance.RollCall.Meeting.Dto;

import jakarta.validation.constraints.NotBlank;

public record MeetingCreateRequestDto(
        @NotBlank(message = "모임 이름은 필수 입력 값입니다.")
        String name
) {
}

