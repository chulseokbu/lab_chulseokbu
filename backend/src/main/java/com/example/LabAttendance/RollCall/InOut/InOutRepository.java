package com.example.LabAttendance.RollCall.InOut;

import com.example.LabAttendance.RollCall.Attendance.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface InOutRepository extends JpaRepository<InOut, Long> {

}
