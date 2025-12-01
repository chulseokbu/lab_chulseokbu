package com.example.LabAttendance.RollCall.Attendance;

import com.example.LabAttendance.RollCall.Member.Member;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Table(
        name = "attendance",
        indexes = {
                @Index(name = "idx_attendance_date", columnList = "date")
        }
)
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    private LocalDate date; // 얘는 생성 시점에 결정, 그날의 날짜이기 때문

    private LocalTime startTime; // 얘는 객체를 생성, 호출하는 시점에 할당

    private Long total; // 객체 생성 시점에 0으로 할당.

    private AttendanceStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id")
    private Member member;

    protected void onCreate() {
        this.date = LocalDate.now();
        this.startTime = LocalTime.now();
        this.total = 0L;
        this.status = AttendanceStatus.IN;
    }

    protected void checkInMember(Member member) {
        this.member = member;
    }

    // 객체 호출 시점에 사용하기
    protected void startCount(LocalTime startTime) {
        this.startTime = startTime;
    }

    // 누적 시간의 합을 구하는 메소드
    protected void calculateAttendance(LocalTime endTime) {
        long minutes = java.time.Duration.between(this.startTime, endTime).toMinutes();
        this.total += minutes; // 누적
    }

    protected void toggleAttendance() {
        if (this.status == AttendanceStatus.IN) {
            this.status = AttendanceStatus.OUT;
        } else if (this.status == AttendanceStatus.OUT) {
            this.status = AttendanceStatus.IN;

        }

    }
}
