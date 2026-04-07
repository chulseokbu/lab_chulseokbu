package com.example.LabAttendance.RollCall.global;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;

/**
 * 랩실·출석 비즈니스 기준 시각(한국 표준시).
 * Railway 등 JVM 기본 타임존이 UTC일 때 {@link LocalDate#now()} / {@link LocalTime#now()} 를 쓰면 날짜·시각이 어긋납니다.
 */
public final class KoreaTime {

    public static final ZoneId ZONE = ZoneId.of("Asia/Seoul");

    private KoreaTime() {
    }

    public static LocalDate today() {
        return LocalDate.now(ZONE);
    }

    public static LocalTime nowTime() {
        return LocalTime.now(ZONE);
    }

    public static LocalDateTime nowDateTime() {
        return LocalDateTime.now(ZONE);
    }
}
