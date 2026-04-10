package com.example.LabAttendance.RollCall.Meeting.Dto;

import jakarta.validation.constraints.NotNull;

public record DelegateLeaderRequestDto(
        @NotNull(message = "새 모임장 회원 ID는 필수입니다.")
        Long newLeaderMemberId
) {
}
