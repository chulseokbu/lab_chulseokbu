package com.example.LabAttendance.RollCall.global.Exception;

public class AlreadyInMeetingException extends RuntimeException {
    public AlreadyInMeetingException(String message) {
        super(message);
    }
}
