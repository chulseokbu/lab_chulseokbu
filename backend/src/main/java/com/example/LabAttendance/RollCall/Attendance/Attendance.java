package com.example.LabAttendance.RollCall.Attendance;

import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.Member.Member;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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

    private Long total; // 객체 생성 시점에 0으로 할당.

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttendanceStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id")
    private Member member;

    @OneToMany(mappedBy = "attendance",cascade = CascadeType.REMOVE)
    private List<InOut> inOuts = new ArrayList<>();

    protected void onCreate() {
        this.date = LocalDate.now();
        this.total = 0L;
        this.status = AttendanceStatus.IN;
    }

    protected void checkInMember(Member member) {
        this.member = member;
    }

    protected void toggleAttendance() {
        if (this.status == AttendanceStatus.IN) {
            this.status = AttendanceStatus.OUT;
        } else if (this.status == AttendanceStatus.OUT) {
            this.status = AttendanceStatus.IN;

        }
    }

    protected void addInOut(long minute) {
        this.total = this.total + minute;
    }
}

