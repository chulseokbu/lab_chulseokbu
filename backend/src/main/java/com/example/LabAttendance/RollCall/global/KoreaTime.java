package com.example.LabAttendance.RollCall.global;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

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

    /**
     * JSON 응답용: 해당 출석일의 시각을 KST 오프셋이 붙은 ISO-8601로 직렬화한다.
     * (프론트가 순수 HH:mm 을 기기 로컬/추측으로 해석하지 않도록)
     */
    public static String formatOffsetDateTime(LocalDate date, LocalTime time) {
        if (date == null || time == null) {
            return null;
        }
        return date.atTime(time).atZone(ZONE).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }
}
