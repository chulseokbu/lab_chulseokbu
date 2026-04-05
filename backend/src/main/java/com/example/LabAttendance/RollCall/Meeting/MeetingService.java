package com.example.LabAttendance.RollCall.Meeting;

import com.example.LabAttendance.RollCall.Meeting.Dto.*;
import com.example.LabAttendance.RollCall.Member.Member;
import com.example.LabAttendance.RollCall.Member.MemberRepository;
import com.example.LabAttendance.RollCall.global.Exception.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@Service
@Transactional
public class MeetingService {

    private static final int INVITE_CODE_BYTES = 9;
    private static final int INVITE_CODE_MAX_ATTEMPTS = 64;

    private final MeetingRepository meetingRepository;
    private final MeetingMembershipRepository membershipRepository;
    private final MemberRepository memberRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    public MeetingCreatedResponseDto createMeeting(Long creatorMemberId, String name) {
        Member creator = memberRepository.findById(creatorMemberId)
                .orElseThrow(() -> new MemberNotFoundException("회원을 찾을 수 없습니다."));
        Instant now = Instant.now();
        String code = generateUniqueInviteCode();
        Meeting meeting = new Meeting(name.trim(), code, now);
        meetingRepository.save(meeting);
        membershipRepository.save(new MeetingMembership(meeting, creator, MeetingRole.LEADER, now));
        return new MeetingCreatedResponseDto(meeting.getId(), meeting.getName(), code, MeetingRole.LEADER);
    }

    public MeetingSummaryResponseDto joinMeeting(Long memberId, String inviteCode) {
        Meeting meeting = meetingRepository.findByInviteCode(inviteCode.trim())
                .orElseThrow(() -> new InvalidInviteCodeException("유효하지 않은 초대 코드입니다."));
        if (membershipRepository.existsByMeeting_IdAndMember_Id(meeting.getId(), memberId)) {
            throw new AlreadyInMeetingException("이미 이 모임에 속해 있습니다.");
        }
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new MemberNotFoundException("회원을 찾을 수 없습니다."));
        membershipRepository.save(new MeetingMembership(meeting, member, MeetingRole.MEMBER, Instant.now()));
        return new MeetingSummaryResponseDto(meeting.getId(), meeting.getName(), MeetingRole.MEMBER);
    }

    @Transactional(readOnly = true)
    public List<MeetingSummaryResponseDto> listMyMeetings(Long memberId) {
        return membershipRepository.findByMember_IdOrderByJoinedAtAsc(memberId).stream()
                .map(m -> new MeetingSummaryResponseDto(
                        m.getMeeting().getId(),
                        m.getMeeting().getName(),
                        m.getRole()
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public MeetingDetailResponseDto getMeeting(Long memberId, Long meetingId) {
        Meeting meeting = meetingRepository.findById(meetingId)
                .orElseThrow(() -> new MeetingNotFoundException("모임을 찾을 수 없습니다."));
        MeetingMembership mine = membershipRepository.findByMeeting_IdAndMember_Id(meetingId, memberId)
                .orElseThrow(() -> new NotMeetingMemberException("이 모임의 구성원이 아닙니다."));
        List<MeetingMembership> rows = membershipRepository.findByMeeting_IdOrderByJoinedAtAsc(meetingId);
        String inviteCode = mine.getRole() == MeetingRole.LEADER ? meeting.getInviteCode() : null;
        List<MeetingMemberResponseDto> members = rows.stream()
                .map(r -> new MeetingMemberResponseDto(
                        r.getMember().getId(),
                        r.getMember().getNickname(),
                        r.getRole(),
                        r.getJoinedAt()
                ))
                .toList();
        return new MeetingDetailResponseDto(meeting.getId(), meeting.getName(), inviteCode, mine.getRole(), members);
    }

    /**
     * 회원 탈퇴 시 호출. 속한 모든 모임에서 나가며, 모임장인 경우 {@link #leaveMeeting}과 동일하게
     * 가장 오래된 구성원에게 모임장을 위임하고, 남은 구성원이 없으면 모임을 삭제합니다.
     */
    public void leaveAllMeetingsForMember(Long memberId) {
        List<Long> meetingIds = membershipRepository.findByMember_IdOrderByJoinedAtAsc(memberId).stream()
                .map(m -> m.getMeeting().getId())
                .distinct()
                .toList();
        for (Long meetingId : meetingIds) {
            leaveMeeting(memberId, meetingId);
        }
    }

    public void leaveMeeting(Long memberId, Long meetingId) {
        Meeting meeting = meetingRepository.findById(meetingId)
                .orElseThrow(() -> new MeetingNotFoundException("모임을 찾을 수 없습니다."));
        MeetingMembership mine = membershipRepository.findByMeeting_IdAndMember_Id(meetingId, memberId)
                .orElseThrow(() -> new NotMeetingMemberException("이 모임의 구성원이 아닙니다."));
        if (mine.getRole() == MeetingRole.MEMBER) {
            membershipRepository.delete(mine);
            return;
        }
        membershipRepository.delete(mine);
        Optional<MeetingMembership> successor = membershipRepository
                .findFirstByMeeting_IdAndRoleOrderByJoinedAtAsc(meetingId, MeetingRole.MEMBER);
        if (successor.isEmpty()) {
            meetingRepository.delete(meeting);
        } else {
            successor.get().setRole(MeetingRole.LEADER);
        }
    }

    public void deleteMeeting(Long memberId, Long meetingId) {
        Meeting meeting = meetingRepository.findById(meetingId)
                .orElseThrow(() -> new MeetingNotFoundException("모임을 찾을 수 없습니다."));
        MeetingMembership mine = membershipRepository.findByMeeting_IdAndMember_Id(meetingId, memberId)
                .orElseThrow(() -> new NotMeetingMemberException("이 모임의 구성원이 아닙니다."));
        if (mine.getRole() != MeetingRole.LEADER) {
            throw new NotMeetingLeaderException("모임 삭제는 모임장만 할 수 있습니다.");
        }
        membershipRepository.deleteByMeeting_Id(meetingId);
        meetingRepository.delete(meeting);
    }

    public void delegateLeadership(Long currentLeaderMemberId, Long meetingId, Long newLeaderMemberId) {
        if (currentLeaderMemberId.equals(newLeaderMemberId)) {
            throw new IllegalArgumentException("자기 자신에게 위임할 수 없습니다.");
        }
        meetingRepository.findById(meetingId)
                .orElseThrow(() -> new MeetingNotFoundException("모임을 찾을 수 없습니다."));
        MeetingMembership leaderRow = membershipRepository.findByMeeting_IdAndMember_Id(meetingId, currentLeaderMemberId)
                .orElseThrow(() -> new NotMeetingMemberException("이 모임의 구성원이 아닙니다."));
        if (leaderRow.getRole() != MeetingRole.LEADER) {
            throw new NotMeetingLeaderException("모임장만 권한을 위임할 수 있습니다.");
        }
        MeetingMembership target = membershipRepository.findByMeeting_IdAndMember_Id(meetingId, newLeaderMemberId)
                .orElseThrow(() -> new NotMeetingMemberException("선택한 회원은 이 모임의 구성원이 아닙니다."));
        if (target.getRole() == MeetingRole.LEADER) {
            return;
        }
        leaderRow.setRole(MeetingRole.MEMBER);
        target.setRole(MeetingRole.LEADER);
    }

    private String generateUniqueInviteCode() {
        for (int i = 0; i < INVITE_CODE_MAX_ATTEMPTS; i++) {
            byte[] buf = new byte[INVITE_CODE_BYTES];
            secureRandom.nextBytes(buf);
            String code = Base64.getUrlEncoder().withoutPadding().encodeToString(buf);
            if (!meetingRepository.existsByInviteCode(code)) {
                return code;
            }
        }
        throw new IllegalStateException("초대 코드를 생성하지 못했습니다. 다시 시도해 주세요.");
    }
}
