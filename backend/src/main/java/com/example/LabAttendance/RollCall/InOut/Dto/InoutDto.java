package com.example.LabAttendance.RollCall.InOut.Dto;

import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.global.KoreaTime;

public record InoutDto(
        Long inoutId,
        String date,
        String checkIn,
        String checkOut
) {

    public static InoutDto from(InOut inOut) {
        var d = inOut.getAttendance().getDate();
        return new InoutDto(
                inOut.getId(),
                d.toString(),
                KoreaTime.formatOffsetDateTime(d, inOut.getStartTime()),
                KoreaTime.formatOffsetDateTime(d, inOut.getEndTime())
        );
    }
}
