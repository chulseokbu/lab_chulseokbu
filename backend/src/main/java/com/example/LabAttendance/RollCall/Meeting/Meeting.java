package com.example.LabAttendance.RollCall.Meeting;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "meetings")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Meeting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, unique = true, length = 64)
    private String inviteCode;

    @Column(nullable = false)
    private Instant createdAt;

    public Meeting(String name, String inviteCode, Instant createdAt) {
        this.name = name;
        this.inviteCode = inviteCode;
        this.createdAt = createdAt;
    }
}
