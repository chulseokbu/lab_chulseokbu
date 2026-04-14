package com.example.LabAttendance.RollCall.Attendance;


import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.InOut.InOutRepository;
import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.Member.MemberRepository;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckInException;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckOutException;
import com.example.LabAttendance.RollCall.global.Exception.NotAttendanceTodayException;
import com.example.LabAttendance.RollCall.global.KoreaTime;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AttendanceServiceTest {

    @InjectMocks
    AttendanceService attendanceService;

    @Mock
    AttendanceRepository attendanceRepository;

    @Mock
    MemberRepository memberRepository;

    @Mock
    InOutRepository inOutRepository;

    Member member;

    @BeforeEach
    void setUp() {
        member = new Member();
        ReflectionTestUtils.setField(member, "id", 1L);
        ReflectionTestUtils.setField(member, "memberNum", 20250001L);
        ReflectionTestUtils.setField(member, "nickname", "Tom");
        ReflectionTestUtils.setField(member, "password", "encoded-password");
        ReflectionTestUtils.setField(member, "email", "tom@test.com");
        ReflectionTestUtils.setField(member, "phone", "01012345678");
    }

    @Test
    void checkInLab_shouldCreateNewAttendanceAndInOut_whenFirstCheckInToday() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(attendanceRepository.findByMemberIdAndDate(member.getId(), KoreaTime.today()))
                .thenReturn(Optional.empty());
        when(inOutRepository.save(any(InOut.class))).thenAnswer(invocation -> {
            InOut io = invocation.getArgument(0);
            ReflectionTestUtils.setField(io, "id", 10L);
            return io;
        });

        Long inoutId = attendanceService.checkInLab(1L);

        assertThat(inoutId).isEqualTo(10L);
        verify(attendanceRepository, times(2)).save(any(Attendance.class));
        verify(inOutRepository).save(any(InOut.class));
    }

    @Test
    void checkInLab_shouldThrow_whenAlreadyCheckedIn() {
        Attendance attendance = new Attendance();
        ReflectionTestUtils.setField(attendance, "member", member);
        ReflectionTestUtils.setField(attendance, "date", KoreaTime.today());
        ReflectionTestUtils.setField(attendance, "total", 0L);
        ReflectionTestUtils.setField(attendance, "status", AttendanceStatus.IN);

        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(attendanceRepository.findByMemberIdAndDate(member.getId(), KoreaTime.today()))
                .thenReturn(Optional.of(attendance));

        assertThatThrownBy(() -> attendanceService.checkInLab(1L))
                .isInstanceOf(AlreadyCheckInException.class);
    }

    @Test
    void checkOutLab_shouldEndInOutAndUpdateAttendance_whenValid() throws NotAttendanceTodayException {
        Attendance attendance = new Attendance();
        ReflectionTestUtils.setField(attendance, "member", member);
        ReflectionTestUtils.setField(attendance, "date", KoreaTime.today());
        ReflectionTestUtils.setField(attendance, "total", 0L);
        ReflectionTestUtils.setField(attendance, "status", AttendanceStatus.IN);

        InOut inOut = new InOut();
        inOut.checkStart(attendance, KoreaTime.nowTime().minusMinutes(5));
        ReflectionTestUtils.setField(inOut, "id", 10L);

        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(inOutRepository.findById(10L)).thenReturn(Optional.of(inOut));
        when(attendanceRepository.findByMemberIdAndDate(member.getId(), KoreaTime.today()))
                .thenReturn(Optional.of(attendance));

        attendanceService.checkOutLab(1L, 10L);

        assertThat(inOut.getEndTime()).isNotNull();
        assertThat(attendance.getStatus()).isEqualTo(AttendanceStatus.OUT);
        verify(attendanceRepository).save(attendance);
        verify(inOutRepository).save(inOut);
    }

    @Test
    void checkOutLab_shouldThrow_whenNoAttendanceToday() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(inOutRepository.findById(10L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> attendanceService.checkOutLab(1L, 10L))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("출입 내역이 없습니다");
    }

    @Test
    void checkOutLab_shouldThrow_whenAlreadyCheckedOut() {
        Attendance attendance = new Attendance();
        ReflectionTestUtils.setField(attendance, "member", member);
        ReflectionTestUtils.setField(attendance, "date", KoreaTime.today());
        ReflectionTestUtils.setField(attendance, "total", 0L);
        ReflectionTestUtils.setField(attendance, "status", AttendanceStatus.IN);

        InOut inOut = new InOut();
        inOut.checkStart(attendance, KoreaTime.nowTime().minusMinutes(5));
        inOut.checkEnd(KoreaTime.nowTime().minusMinutes(1));
        ReflectionTestUtils.setField(inOut, "id", 10L);

        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(inOutRepository.findById(10L)).thenReturn(Optional.of(inOut));

        assertThatThrownBy(() -> attendanceService.checkOutLab(1L, 10L))
                .isInstanceOf(AlreadyCheckOutException.class)
                .hasMessageContaining("이미 처리된 출석 기록입니다.");
    }

    @Test
    void checkOutLab_shouldThrow_whenMemberNotFound() {
        when(memberRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> attendanceService.checkOutLab(1L, 10L))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("로그인 먼저 진행해 주세요");
    }
}
