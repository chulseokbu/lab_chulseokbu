package com.example.LabAttendance.RollCall.Meeting.Dto;

import com.example.LabAttendance.RollCall.InOut.Dto.InoutDto;

import java.util.List;

public record MemberWeekStayDto(
        Long memberId,
        String name,
        List<InoutDto> records
) {
}

