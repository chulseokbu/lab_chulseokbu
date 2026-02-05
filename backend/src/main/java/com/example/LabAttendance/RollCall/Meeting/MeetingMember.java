package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Member.Member;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Getter
@NoArgsConstructor
@Table(
        name = "meeting_member",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_meeting_member", columnNames = {"meeting_id", "member_id"})
        },
        indexes = {
                @Index(name = "idx_meeting_member_meeting", columnList = "meeting_id"),
                @Index(name = "idx_meeting_member_member", columnList = "member_id")
        }
)
public class MeetingMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "meeting_id")
    private Meeting meeting;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id")
    private Member member;

    @Column(nullable = false)
    private LocalDateTime joinedAt;

    public MeetingMember(Meeting meeting, Member member) {
        this.meeting = meeting;
        this.member = member;
        this.joinedAt = LocalDateTime.now();
    }
}

