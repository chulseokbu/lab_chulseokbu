package com.example.LabAttendance.RollCall.Meeting.Dto;

import jakarta.validation.constraints.NotBlank;

public record JoinMeetingRequestDto(
        @NotBlank(message = "초대 코드는 필수입니다.")
        String inviteCode
) {
}
