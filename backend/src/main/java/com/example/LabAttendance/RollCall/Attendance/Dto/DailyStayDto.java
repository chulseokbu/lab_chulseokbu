package com.example.LabAttendance.RollCall.Attendance.Dto;


import com.example.LabAttendance.RollCall.Attendance.Attendance;
import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.global.KoreaTime;

import java.time.Duration;
import java.time.LocalTime;

public record DailyStayDto(
        Long attendanceId,
        String date,
        Long stayMinutes,
        double stayHours,
        String duration
) {

    public static DailyStayDto from(Attendance attendance) {
        long minutes = attendance.getTotal() != null ? attendance.getTotal() : 0L;
        LocalTime now = KoreaTime.nowTime();
        for (InOut io : attendance.getInOuts()) {
            if (io.getEndTime() == null) {
                long extra = Duration.between(io.getStartTime(), now).toMinutes();
                minutes += Math.max(0, extra);
            }
        }
        double hours = minutes / 60.0;

        String durationStr = toKoreanDuration(minutes);

        return new DailyStayDto(
                attendance.getId(),
                attendance.getDate().toString(),
                minutes,
                hours,
                durationStr
        );
    }

    private static String toKoreanDuration(long minutes) {
        if (minutes <= 0) return "0분";
        long h = minutes / 60;
        long m = minutes % 60;
        if (h <= 0) return m + "분";
        if (m <= 0) return h + "시간";
        return h + "시간 " + m + "분";
    }
}
