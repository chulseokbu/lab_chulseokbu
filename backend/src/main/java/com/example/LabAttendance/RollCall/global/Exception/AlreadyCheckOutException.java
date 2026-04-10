package com.example.LabAttendance.RollCall.global.Exception;

public class AlreadyCheckOutException extends RuntimeException {
    public AlreadyCheckOutException(String message) {
        super(message);
    }
}

