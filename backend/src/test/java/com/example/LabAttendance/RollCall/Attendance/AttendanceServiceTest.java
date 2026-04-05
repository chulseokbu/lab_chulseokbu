package com.example.LabAttendance.RollCall.Attendance;


import com.example.LabAttendance.RollCall.InOut.InOut;
import com.example.LabAttendance.RollCall.InOut.InOutRepository;
import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.Member.MemberRepository;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckInException;
import com.example.LabAttendance.RollCall.global.Exception.NotAttendanceTodayException;
import com.example.LabAttendance.RollCall.global.Gender;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
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
    Attendance attendance;
    InOut inOut;

    @BeforeEach
    void setUp() {
        member = new Member(null, 20250001L, "Tom", "pw", "tom@test.com", "01012345678", Gender.MALE, null);
        ReflectionTestUtils.setField(member, "id", 1L);

        attendance = mock(Attendance.class);
        when(attendance.getStatus()).thenReturn(AttendanceStatus.IN);

        inOut = new InOut();
        ReflectionTestUtils.setField(inOut, "id", 15L);
    }

    @Test
    void checkInLab_throws_whenMemberNotFound() {
        when(memberRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> attendanceService.checkInLab(1L))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void checkInLab_throws_whenAlreadyCheckedIn() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(attendanceRepository.findByIdAndDate(1L, LocalDate.now())).thenReturn(Optional.of(attendance));
        when(attendance.getStatus()).thenReturn(AttendanceStatus.IN);

        assertThatThrownBy(() -> attendanceService.checkInLab(1L))
                .isInstanceOf(AlreadyCheckInException.class)
                .hasMessageContaining("이미 체크인");
    }

    @Test
    void checkInLab_createsAttendanceAndReturnsInOutId_whenNoAttendanceToday() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(attendanceRepository.findByIdAndDate(1L, LocalDate.now())).thenReturn(Optional.empty());
        when(attendanceRepository.save(any(Attendance.class))).thenAnswer(inv -> inv.getArgument(0));
        when(inOutRepository.save(any(InOut.class))).thenAnswer(inv -> {
            InOut io = inv.getArgument(0);
            ReflectionTestUtils.setField(io, "id", 99L);
            return io;
        });

        Long checkInId = attendanceService.checkInLab(1L);

        assertThat(checkInId).isEqualTo(99L);
        verify(attendanceRepository, atLeastOnce()).save(any(Attendance.class));
        verify(inOutRepository).save(any(InOut.class));
    }

    @Test
    void checkOutLab_updates_whenValidInOut() throws NotAttendanceTodayException {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(inOutRepository.findById(15L)).thenReturn(Optional.of(inOut));
        inOut.checkStart(attendance, java.time.LocalTime.of(9, 0));
        ReflectionTestUtils.setField(inOut, "attendance", attendance);
        when(attendance.getStatus()).thenReturn(AttendanceStatus.IN);
        when(attendanceRepository.findByIdAndDate(1L, LocalDate.now())).thenReturn(Optional.of(attendance));

        attendanceService.checkOutLab(1L, 15L);

        verify(attendanceRepository).save(attendance);
        verify(inOutRepository).save(inOut);
    }

    @Test
    void checkOutLab_throws_whenNoAttendanceToday() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(member));
        when(inOutRepository.findById(15L)).thenReturn(Optional.of(inOut));
        inOut.checkStart(attendance, java.time.LocalTime.of(9, 0));
        ReflectionTestUtils.setField(inOut, "attendance", attendance);
        when(attendance.getStatus()).thenReturn(AttendanceStatus.OUT);

        assertThatThrownBy(() -> attendanceService.checkOutLab(1L, 15L))
                .isInstanceOf(NotAttendanceTodayException.class)
                .hasMessageContaining("체크인한 이력이 없습니다");
    }

    @Test
    void checkOutLab_throws_whenMemberNotFound() {
        when(memberRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> attendanceService.checkOutLab(1L, 15L))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessageContaining("로그인 먼저");
    }
}
