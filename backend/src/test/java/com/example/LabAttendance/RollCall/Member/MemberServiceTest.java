package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Meeting.MeetingService;
import com.example.LabAttendance.RollCall.global.Exception.MemberNotFoundException;
import com.example.LabAttendance.RollCall.global.Gender;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MemberServiceTest {

    @InjectMocks
    MemberService memberService;

    @Mock
    MemberRepository memberRepository;

    @Mock
    PasswordEncoder passwordEncoder;

    @Mock
    com.example.LabAttendance.RollCall.global.jwt.JwtTokenProvider jwtTokenProvider;

    @Mock
    MeetingService meetingService;

    @Test
    void withdrawAccount_throws_whenPasswordWrong() {
        Member member = new Member(null, 1L, "n", "hash", "e@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(member, "id", 5L);
        when(memberRepository.findById(5L)).thenReturn(Optional.of(member));
        when(passwordEncoder.matches("wrong", "hash")).thenReturn(false);

        assertThatThrownBy(() -> memberService.withdrawAccount(5L, "wrong"))
                .isInstanceOf(BadCredentialsException.class);

        verify(meetingService, never()).leaveAllMeetingsForMember(anyLong());
        verify(memberRepository, never()).delete(any());
    }

    @Test
    void withdrawAccount_leavesMeetingsAndDeletes_whenPasswordOk() {
        Member member = new Member(null, 1L, "n", "hash", "e@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(member, "id", 5L);
        when(memberRepository.findById(5L)).thenReturn(Optional.of(member));
        when(passwordEncoder.matches("ok", "hash")).thenReturn(true);

        memberService.withdrawAccount(5L, "ok");

        verify(meetingService).leaveAllMeetingsForMember(5L);
        verify(memberRepository).delete(member);
    }

    @Test
    void withdrawAccount_throws_whenMemberMissing() {
        when(memberRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> memberService.withdrawAccount(5L, "pw"))
                .isInstanceOf(MemberNotFoundException.class);
    }
}
