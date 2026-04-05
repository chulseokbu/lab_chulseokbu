package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Meeting.MeetingRole;

import java.util.List;

public record MeetingDetailResponseDto(
        Long meetingId,
        String name,
        String inviteCode,
        MeetingRole myRole,
        List<MeetingMemberResponseDto> members
) {
}
