package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.global.KoreaTime;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@NoArgsConstructor
@Table(
        name = "meeting",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_meeting_code", columnNames = {"code"})
        },
        indexes = {
                @Index(name = "idx_meeting_code", columnList = "code")
        }
)
public class Meeting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 6)
    private String code;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private LocalDate createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_member_id")
    private Member createdBy;

    @OneToMany(mappedBy = "meeting", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MeetingMember> members = new ArrayList<>();

    public Meeting(String code, String name, Member createdBy) {
        this.code = code;
        this.name = name;
        this.createdBy = createdBy;
        this.createdAt = KoreaTime.today();
    }

    /** 모임장(생성자) 변경 — 탈퇴·위임 시에만 사용 */
    public void setCreatedBy(Member member) {
        this.createdBy = member;
    }
}

