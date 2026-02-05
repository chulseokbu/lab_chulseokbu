package com.example.LabAttendance.RollCall.Attendance.Dto;


import com.example.LabAttendance.RollCall.Attendance.Attendance;

public record DailyStayDto(
        Long attendanceId,
        String date,
        Long stayMinutes,
        double stayHours,
        String duration
) {

    public static DailyStayDto from(Attendance attendance) {
        Long minutes = attendance.getTotal();
        double hours = minutes / 60.0;

        String duration = toKoreanDuration(minutes);

        return new DailyStayDto(
                attendance.getId(),
                attendance.getDate().toString(),
                minutes,
                hours,
                duration
        );
    }

    private static String toKoreanDuration(Long minutes) {
        if (minutes == null || minutes <= 0) return "0분";
        long h = minutes / 60;
        long m = minutes % 60;
        if (h <= 0) return m + "분";
        if (m <= 0) return h + "시간";
        return h + "시간 " + m + "분";
    }
}

