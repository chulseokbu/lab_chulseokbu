package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Attendance.Attendance;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long memberNum; // 학번

    @Column(nullable = false)
    private String nickname;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String phone;

    @OneToMany(mappedBy = "member", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Attendance> attandenceList = new ArrayList<>();

    /** Apple `sub` — 동일 사용자 식별. 이메일 로그인만 쓰는 회원은 null */
    @Column(unique = true, length = 255)
    private String appleSub;

    public void updateProfile(String nickname, String email, String phone) {
        this.nickname = nickname;
        this.email = email;
        this.phone = phone;
    }
}
