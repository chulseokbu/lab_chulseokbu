package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.Member.MemberRepository;
import com.example.LabAttendance.RollCall.Meeting.Dto.MeetingCreatedResponseDto;
import com.example.LabAttendance.RollCall.Meeting.Dto.MeetingSummaryResponseDto;
import com.example.LabAttendance.RollCall.global.Exception.*;
import com.example.LabAttendance.RollCall.global.Gender;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MeetingServiceTest {

    @InjectMocks
    MeetingService meetingService;

    @Mock
    MeetingRepository meetingRepository;

    @Mock
    MeetingMembershipRepository membershipRepository;

    @Mock
    MemberRepository memberRepository;

    @Test
    void createMeeting_savesMeetingAndLeaderMembership() {
        Member creator = new Member(null, 20240001L, "boss", "pw", "b@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(creator, "id", 10L);
        when(memberRepository.findById(10L)).thenReturn(Optional.of(creator));
        when(meetingRepository.existsByInviteCode(anyString())).thenReturn(false);
        when(meetingRepository.save(any(Meeting.class))).thenAnswer(inv -> {
            Meeting m = inv.getArgument(0);
            ReflectionTestUtils.setField(m, "id", 99L);
            return m;
        });

        MeetingCreatedResponseDto dto = meetingService.createMeeting(10L, " 스터디 ");

        assertThat(dto.meetingId()).isEqualTo(99L);
        assertThat(dto.name()).isEqualTo("스터디");
        assertThat(dto.myRole()).isEqualTo(MeetingRole.LEADER);
        assertThat(dto.inviteCode()).isNotBlank();

        ArgumentCaptor<MeetingMembership> cap = ArgumentCaptor.forClass(MeetingMembership.class);
        verify(membershipRepository).save(cap.capture());
        assertThat(cap.getValue().getRole()).isEqualTo(MeetingRole.LEADER);
    }

    @Test
    void joinMeeting_returnsMemberRole() {
        Meeting meeting = new Meeting("g", "code1", Instant.now());
        ReflectionTestUtils.setField(meeting, "id", 1L);
        Member user = new Member(null, 1L, "u", "pw", "u@test.com", "010", Gender.FEMALE, null);
        ReflectionTestUtils.setField(user, "id", 5L);
        when(meetingRepository.findByInviteCode("code1")).thenReturn(Optional.of(meeting));
        when(membershipRepository.existsByMeeting_IdAndMember_Id(1L, 5L)).thenReturn(false);
        when(memberRepository.findById(5L)).thenReturn(Optional.of(user));

        MeetingSummaryResponseDto dto = meetingService.joinMeeting(5L, "code1");

        assertThat(dto.meetingId()).isEqualTo(1L);
        assertThat(dto.myRole()).isEqualTo(MeetingRole.MEMBER);
        verify(membershipRepository).save(any(MeetingMembership.class));
    }

    @Test
    void deleteMeeting_throws_whenCallerIsMember() {
        Meeting meeting = new Meeting("g", "c", Instant.now());
        ReflectionTestUtils.setField(meeting, "id", 1L);
        Member member = new Member(null, 1L, "m", "pw", "m@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(member, "id", 2L);
        MeetingMembership row = new MeetingMembership(meeting, member, MeetingRole.MEMBER, Instant.now());
        when(meetingRepository.findById(1L)).thenReturn(Optional.of(meeting));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 2L)).thenReturn(Optional.of(row));

        assertThatThrownBy(() -> meetingService.deleteMeeting(2L, 1L))
                .isInstanceOf(NotMeetingLeaderException.class);
        verify(meetingRepository, never()).delete(any());
    }

    @Test
    void leaveMeeting_asLeader_promotesOldestMember() {
        Meeting meeting = new Meeting("g", "c", Instant.now());
        ReflectionTestUtils.setField(meeting, "id", 1L);
        Member leader = new Member(null, 1L, "L", "pw", "l@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(leader, "id", 1L);
        Member olderMember = new Member(null, 2L, "O", "pw", "o@test.com", "010", Gender.FEMALE, null);
        ReflectionTestUtils.setField(olderMember, "id", 2L);
        MeetingMembership leaderRow = new MeetingMembership(meeting, leader, MeetingRole.LEADER, Instant.parse("2024-06-01T00:00:00Z"));
        ReflectionTestUtils.setField(leaderRow, "id", 10L);
        MeetingMembership memberRow = new MeetingMembership(meeting, olderMember, MeetingRole.MEMBER, Instant.parse("2024-01-01T00:00:00Z"));
        ReflectionTestUtils.setField(memberRow, "id", 11L);

        when(meetingRepository.findById(1L)).thenReturn(Optional.of(meeting));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 1L)).thenReturn(Optional.of(leaderRow));
        when(membershipRepository.findFirstByMeeting_IdAndRoleOrderByJoinedAtAsc(1L, MeetingRole.MEMBER))
                .thenReturn(Optional.of(memberRow));

        meetingService.leaveMeeting(1L, 1L);

        verify(membershipRepository).delete(leaderRow);
        assertThat(memberRow.getRole()).isEqualTo(MeetingRole.LEADER);
        verify(meetingRepository, never()).delete(any());
    }

    @Test
    void leaveMeeting_asLeader_deletesMeetingWhenNoOtherMembers() {
        Meeting meeting = new Meeting("g", "c", Instant.now());
        ReflectionTestUtils.setField(meeting, "id", 1L);
        Member leader = new Member(null, 1L, "L", "pw", "l@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(leader, "id", 1L);
        MeetingMembership leaderRow = new MeetingMembership(meeting, leader, MeetingRole.LEADER, Instant.now());

        when(meetingRepository.findById(1L)).thenReturn(Optional.of(meeting));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 1L)).thenReturn(Optional.of(leaderRow));
        when(membershipRepository.findFirstByMeeting_IdAndRoleOrderByJoinedAtAsc(1L, MeetingRole.MEMBER))
                .thenReturn(Optional.empty());

        meetingService.leaveMeeting(1L, 1L);

        verify(membershipRepository).delete(leaderRow);
        verify(meetingRepository).delete(meeting);
    }

    @Test
    void leaveAllMeetingsForMember_callsLeaveMeetingPerMeeting() {
        Meeting m1 = new Meeting("a", "c1", Instant.now());
        ReflectionTestUtils.setField(m1, "id", 1L);
        Meeting m2 = new Meeting("b", "c2", Instant.now());
        ReflectionTestUtils.setField(m2, "id", 2L);
        Member user = new Member(null, 1L, "u", "pw", "u@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(user, "id", 9L);
        MeetingMembership row1 = new MeetingMembership(m1, user, MeetingRole.MEMBER, Instant.now());
        MeetingMembership row2 = new MeetingMembership(m2, user, MeetingRole.MEMBER, Instant.now());

        when(membershipRepository.findByMember_IdOrderByJoinedAtAsc(9L)).thenReturn(List.of(row1, row2));
        when(meetingRepository.findById(1L)).thenReturn(Optional.of(m1));
        when(meetingRepository.findById(2L)).thenReturn(Optional.of(m2));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 9L)).thenReturn(Optional.of(row1));
        when(membershipRepository.findByMeeting_IdAndMember_Id(2L, 9L)).thenReturn(Optional.of(row2));

        meetingService.leaveAllMeetingsForMember(9L);

        verify(membershipRepository, times(2)).delete(any(MeetingMembership.class));
    }

    @Test
    void delegateLeadership_swapsRoles() {
        Meeting meeting = new Meeting("g", "c", Instant.now());
        ReflectionTestUtils.setField(meeting, "id", 1L);
        Member leader = new Member(null, 1L, "L", "pw", "l@test.com", "010", Gender.MALE, null);
        ReflectionTestUtils.setField(leader, "id", 1L);
        Member next = new Member(null, 2L, "N", "pw", "n@test.com", "010", Gender.FEMALE, null);
        ReflectionTestUtils.setField(next, "id", 2L);
        MeetingMembership leaderRow = new MeetingMembership(meeting, leader, MeetingRole.LEADER, Instant.now());
        MeetingMembership nextRow = new MeetingMembership(meeting, next, MeetingRole.MEMBER, Instant.now());

        when(meetingRepository.findById(1L)).thenReturn(Optional.of(meeting));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 1L)).thenReturn(Optional.of(leaderRow));
        when(membershipRepository.findByMeeting_IdAndMember_Id(1L, 2L)).thenReturn(Optional.of(nextRow));

        meetingService.delegateLeadership(1L, 1L, 2L);

        assertThat(leaderRow.getRole()).isEqualTo(MeetingRole.MEMBER);
        assertThat(nextRow.getRole()).isEqualTo(MeetingRole.LEADER);
    }
}
