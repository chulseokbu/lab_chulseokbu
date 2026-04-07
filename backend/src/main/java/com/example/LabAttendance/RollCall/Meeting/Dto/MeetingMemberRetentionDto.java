package com.example.LabAttendance.RollCall.Meeting.Dto;

public record MeetingMemberRetentionDto(
        Long memberId,
        String name,
        String initial,
        boolean isPresent,
        String checkIn,   // present일 때 (HH:mm)
        String lastExit,  // absent일 때 (예: "2026-02-05 18:30")
        String duration   // present일 때(오늘 누적) 또는 null
) {
}

