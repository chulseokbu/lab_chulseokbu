package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Meeting.Meeting;

public record MeetingResponseDto(
        Long id,
        String code,
        String name,
        int memberCount,
        String createdAt
) {
    public static MeetingResponseDto from(Meeting meeting, int memberCount) {
        return new MeetingResponseDto(
                meeting.getId(),
                meeting.getCode(),
                meeting.getName(),
                memberCount,
                meeting.getCreatedAt() != null ? meeting.getCreatedAt().toString() : null
        );
    }
}

