package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Meeting.MeetingRole;

import java.time.Instant;

public record MeetingMemberResponseDto(
        Long memberId,
        String nickname,
        MeetingRole role,
        Instant joinedAt
) {
}
