package com.example.LabAttendance.RollCall.Meeting.Dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateMeetingRequestDto(
        @NotBlank(message = "모임 이름은 필수입니다.")
        @Size(max = 200, message = "모임 이름은 200자 이하여야 합니다.")
        String name
) {
}
