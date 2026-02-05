package com.example.LabAttendance.RollCall.InOut.Dto;

import com.example.LabAttendance.RollCall.InOut.InOut;

import java.time.format.DateTimeFormatter;

public record InoutDto(
        Long inoutId,
        String date,
        String checkIn,
        String checkOut
) {

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    public static InoutDto from(InOut inOut) {
        return new InoutDto(
                inOut.getId(),
                inOut.getAttendance().getDate().toString(),
                inOut.getStartTime() != null ? inOut.getStartTime().format(TIME_FORMATTER) : null,
                inOut.getEndTime() != null ? inOut.getEndTime().format(TIME_FORMATTER) : null
        );
    }
}
