package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.Attendance.Dto.DailyStayDto;

import java.util.List;

public record MemberMonthStayDto(
        Long memberId,
        String name,
        List<DailyStayDto> records
) {
}

