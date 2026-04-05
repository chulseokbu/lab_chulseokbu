package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Member.Member;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(
        name = "meeting_memberships",
        uniqueConstraints = @UniqueConstraint(columnNames = {"meeting_id", "member_id"})
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MeetingMembership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "meeting_id")
    private Meeting meeting;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id")
    private Member member;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MeetingRole role;

    @Column(nullable = false)
    private Instant joinedAt;

    public MeetingMembership(Meeting meeting, Member member, MeetingRole role, Instant joinedAt) {
        this.meeting = meeting;
        this.member = member;
        this.role = role;
        this.joinedAt = joinedAt;
    }

    void setRole(MeetingRole role) {
        this.role = role;
    }
}
