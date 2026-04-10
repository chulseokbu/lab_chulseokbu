package com.example.LabAttendance.RollCall.Member;

import com.example.LabAttendance.RollCall.Meeting.MeetingMemberRepository;
import com.example.LabAttendance.RollCall.Meeting.MeetingRepository;
import com.example.LabAttendance.RollCall.Member.DTO.*;
import com.example.LabAttendance.RollCall.global.Exception.DuplicateEmailException;
import com.example.LabAttendance.RollCall.global.Exception.MemberNotFoundException;
import com.example.LabAttendance.RollCall.global.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;

@RequiredArgsConstructor
@Service
@Transactional
public class MemberService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final MeetingMemberRepository meetingMemberRepository;
    private final MeetingRepository meetingRepository;

    public MemberResponseDto create(MemberSignupRequestDto requestDto) {

        if (memberRepository.existsByEmail(requestDto.email())) {
            throw new DuplicateEmailException("이미 존재하는 이메일입니다: " + requestDto.email());
        }

        String hashedPassword = passwordEncoder.encode(requestDto.password());


        Member member = new Member(
                null,
                requestDto.memberId(),
                requestDto.nickname(),
                hashedPassword,
                requestDto.email(),
                requestDto.phone(),
                requestDto.gender(),
                new ArrayList<>()
        );

        memberRepository.save(member);

        // 생성자 호출 후 ID가 자동 생성되어 member 객체에 반영됨
        return new MemberResponseDto(
                member.getId(),
                member.getMemberNum(),
                member.getNickname(),
                member.getEmail()
        );
    }

    public MemberProfileResponseDto updateProfile(Long memberId, ProfileUpdateRequestDto requestDto) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new MemberNotFoundException("존재하지 않는 회원입니다."));

        if (memberRepository.existsByEmailAndIdNot(requestDto.email(), memberId)) {
            throw new DuplicateEmailException("이미 존재하는 이메일입니다: " + requestDto.email());
        }

        member.updateProfile(requestDto.nickname(), requestDto.email(), requestDto.phone());

        return new MemberProfileResponseDto(
                member.getId(),
                member.getMemberNum(),
                member.getNickname(),
                member.getEmail(),
                member.getPhone()
        );
    }

    public void withdraw(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new MemberNotFoundException("존재하지 않는 회원입니다."));

        meetingMemberRepository.deleteAllByMemberId(memberId);
        meetingRepository.clearCreatedByMemberId(memberId);
        memberRepository.delete(member);
    }

    public LoginResponseDto login(LoginRequestDto requestDto) {

        Member member = memberRepository.findByEmail(requestDto.email())
                .orElseThrow(() -> new MemberNotFoundException("가입되지 않은 이메일입니다."));

        if (!passwordEncoder.matches(requestDto.password(), member.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }


        String jwtToken = jwtTokenProvider.generateToken(member.getId(), member.getEmail());

        return new LoginResponseDto(
                jwtToken,
                member.getMemberNum(),
                member.getNickname(),
                member.getPhone(),
                member.getEmail()
        );
    }
}