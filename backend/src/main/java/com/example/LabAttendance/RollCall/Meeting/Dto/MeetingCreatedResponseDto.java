package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Meeting.MeetingRole;

public record MeetingCreatedResponseDto(
        Long meetingId,
        String name,
        String inviteCode,
        MeetingRole myRole
) {
}
