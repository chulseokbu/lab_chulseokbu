package com.example.LabAttendance.RollCall.Attendance;


import com.example.LabAttendance.RollCall.InOut.Dto.CheckInDto;
import com.example.LabAttendance.RollCall.global.Exception.AlreadyCheckInException;
import com.example.LabAttendance.RollCall.global.Exception.NotAttendanceTodayException;
import com.example.LabAttendance.RollCall.global.ResponneType.ApiResponse;
import com.example.LabAttendance.RollCall.global.ResponneType.NoDataApiResponse;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/lab/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/in")
    public ResponseEntity<ApiResponse<CheckInDto>> checkIn(
            @AuthenticationPrincipal Long memberId)
            {
        try{
            return ResponseEntity.status(200)
                    .body(ApiResponse.success(
                            new CheckInDto(attendanceService.checkInLab(memberId)),"체크인 되었습니다."));
        }catch (AlreadyCheckInException e){
            return ResponseEntity.status(400).body(ApiResponse.failure(e.getMessage()));
        }
    }

    @PostMapping("/out/{inout_id}")
    public ResponseEntity<NoDataApiResponse> checkOut(
            @AuthenticationPrincipal Long memberId,
            @PathVariable(name ="inout_id") Long inoutId
    ){
        try{
            attendanceService.checkOutLab(memberId, inoutId);
            return ResponseEntity.status(200)
                    .body(NoDataApiResponse.success("체크아웃 되었습니다"));
        }catch (NotAttendanceTodayException e){
            return ResponseEntity.status(400)
                    .body(NoDataApiResponse.failure("체크인 먼저 진행해주세요"));
        }catch (AlreadyCheckInException e){
            return ResponseEntity.status(400).body(NoDataApiResponse.failure(e.getMessage()));
        }catch(EntityNotFoundException e){
            return ResponseEntity.status(404).body(NoDataApiResponse.failure(e.getMessage()));
        }
    }


}
