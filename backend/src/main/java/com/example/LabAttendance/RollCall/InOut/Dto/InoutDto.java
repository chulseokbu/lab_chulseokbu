package com.example.LabAttendance.RollCall.InOut.Dto;

import com.example.LabAttendance.RollCall.InOut.InOut;

import java.time.LocalDate;
import java.time.LocalTime;

public record InoutDto(
        Long inOutId,
        LocalDate date,
        LocalTime startTime,
        LocalTime endTime
) {

    public static InoutDto from(InOut inOut) {
        return new InoutDto(
                inOut.getId(),
                inOut.getAttendance().getDate(),
                inOut.getStartTime(),
                inOut.getEndTime()
        );
    }
}
