package com.example.LabAttendance.RollCall;

import com.example.LabAttendance.RollCall.global.KoreaTime;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
public class RollCallApplication {

	public static void main(String[] args) {
		TimeZone.setDefault(TimeZone.getTimeZone(KoreaTime.ZONE));
		SpringApplication.run(RollCallApplication.class, args);
	}

}
