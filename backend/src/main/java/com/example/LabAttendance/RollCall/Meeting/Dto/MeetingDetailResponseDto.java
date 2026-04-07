package com.example.LabAttendance.RollCall.Meeting.Dto;

import java.util.List;

public record MeetingDetailResponseDto(
        Long meetingId,
        String name,
        String code,
        String inviteCode,
        String myRole,
        List<MeetingMemberItemDto> members
) {
}
