package com.example.LabAttendance.RollCall.Meeting.Dto;

public record MeetingMemberRetentionDto(
        Long memberId,
        String name,
        String initial,
        boolean isPresent,
        String checkIn,   // present일 때 ISO-8601 KST (예: 2026-04-07T13:37:00+09:00)
        String lastExit,  // absent일 때 동일 형식
        String duration   // present일 때(오늘 누적) 또는 null
) {
}

