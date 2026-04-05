package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Meeting.MeetingRole;

public record MeetingSummaryResponseDto(
        Long meetingId,
        String name,
        MeetingRole myRole
) {
}
