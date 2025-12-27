package com.example.LabAttendance.RollCall.Attendance.Dto;


import com.example.LabAttendance.RollCall.Attendance.Attendance;

public record DailyStayDto(
        Long attendanceId,
        String date,
        Long stayMinutes,
        double stayHours
) {

    public static DailyStayDto from(Attendance attendance) {
        Long minutes = attendance.getTotal();
        double hours = minutes / 60.0;

        return new DailyStayDto(
                attendance.getId(),
                attendance.getDate().toString(),
                minutes,
                hours
        );
    }
}

