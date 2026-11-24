create database hospital;
use hospital;

CREATE TABLE patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    patient_name VARCHAR(50),
    age INT,
    gender VARCHAR(20),
    city VARCHAR(50),
    patient_type VARCHAR(20),
    preferred_time_slot VARCHAR(20),
    registration_date DATE
);

CREATE TABLE doctors (
    doctor_id VARCHAR(10) PRIMARY KEY,
    doctor_name VARCHAR(50),
    specialty VARCHAR(50),
    hire_date DATE,
    rating DECIMAL(3,2),
    employment_type varchar(30),
    is_active varchar(3)
);

CREATE TABLE rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    room_type VARCHAR(30),
    floor INT,
    equipment_type VARCHAR(50),
    capacity INT,
    last_maintenance_date DATE,
    is_available VARCHAR(3)
);

CREATE TABLE appointments (
    appointment_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    appointment_date DATE,
    doctor_id VARCHAR(10),
    service_type VARCHAR(30),
    priority VARCHAR(20),
    estimated_cost DECIMAL(10,2),
    booking_channel VARCHAR(30),

    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE treatments (
    treatment_id VARCHAR(10) PRIMARY KEY,
    appointment_id VARCHAR(10),
    doctor_id VARCHAR(10),
    room_id VARCHAR(10),
    actual_treatment_date DATE,
    status VARCHAR(30),
    treatment_attempt INT,
    treatment_duration_min INT,
    waiting_time_min INT,
    treatment_cost DECIMAL(10,2),

    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);


select * from patients;
select * from doctors;
select * from rooms;
select * from appointments;
select * from treatments;

-- 1. What is the total number of patients?
select count(patient_id) as number_of_patients from patients;

-- 2. What is the total number of appointments?
select count(appointment_id) as number_of_appointments from appointments;

-- 3. What is the total number of treatment records?
select count(treatment_id) as number_of_treatment from treatments;

-- 4. What are the different medical service types?
select distinct(service_type) as service_types from appointments;

-- 5. How many doctors are currently active?
select count(doctor_id) as number_of_doc from doctors where is_active='Yes' ;

-- 6. What are the different room types?
select distinct(room_type) as room_types from rooms;

-- 7. What is the total estimated appointment value?
select sum(estimated_cost) as total_appointment_value from appointments;

-- 8. What is the average treatment duration?
select avg(treatment_duration_min) as average_treatment_duration from treatments;


-- Understand Patient and Appointment Demand.
-- appointment count by city
select count(a.appointment_id) as number_of_appointment,p.city 
from appointments a 
join patients p on a.patient_id=p.patient_id 
group by(city) 
ORDER BY number_of_appointment DESC;

-- appointment based on service types and priorities.
select service_type,priority,count(appointment_id) as number_of_appointment from appointments group by service_type,priority ORDER BY number_of_appointment DESC;

-- appointment volume over time.
select year(appointment_date),month(appointment_date) as months,
count(appointment_id)as number_of_appointment
 from appointments 
 group by year(appointment_date),month(appointment_date) 
 order by number_of_appointment desc;

-- estimated appointment value across patient types 
select  p.patient_type,sum(a.estimated_cost) as total_cost from appointments a join patients p on a.patient_id=p.patient_id group by(p.patient_type);

-- booking channels and their contribution to demand.
select booking_channel,count(appointment_id) as number_of_appointment from appointments group by(booking_channel) order by(number_of_appointment) desc;


-- Patient Appointment Behaviour.

-- Compare patients by number of appointments.
select p.patient_id,count(a.appointment_id) from appointments a join patients p on a.patient_id=p.patient_id group by(patient_id);

-- higher cumulative estimated appointment value.
select patient_id,sum(estimated_cost) as cumulative_value from appointments group by(patient_id) order by(cumulative_value) desc;

-- patient activity across cities
SELECT 
    p.city,
    COUNT(a.appointment_id) AS number_of_appointments
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.city;

-- Compare General, Corporate, and Insurance patients.
select patient_type,count(appointment_id) from patients p join appointments a on p.patient_id=a.patient_id group by(patient_type);

-- patient booking patterns over time.
SELECT 
    YEAR(appointment_date) AS appointment_year,
    MONTH(appointment_date) AS appointment_month,
    booking_channel,
    COUNT(appointment_id) AS number_of_appointments
FROM appointments
GROUP BY 
    YEAR(appointment_date),
    MONTH(appointment_date),
    booking_channel
ORDER BY 
    appointment_year,
    appointment_month,
    number_of_appointments DESC;
    
-- Evaluate Treatment Performance.

-- treatment outcomes across cities.
select p.city,t.status,count(status) from patients p inner join  appointments a on p.patient_id=a.patient_id inner join treatments t on t.appointment_id=a.appointment_id group by p.city,t.status;

-- avg treatment duration and waiting time.
select avg(treatment_duration_min),avg(waiting_time_min) from treatments;

-- Compare Completed, Cancelled, No-Show, Rescheduled, and In Progress outcomes.
select status,count(status) from treatments group by status;

-- dentify areas with higher treatment activity or poorer outcomes.
select p.city,t.status,count(treatment_id) from patients p inner join  appointments a on p.patient_id=a.patient_id inner join treatments t on t.appointment_id=a.appointment_id group by p.city,t.status;

-- treatment performance over time.
select month(actual_treatment_date) as months,status,count(treatment_id) from treatments group by month(actual_treatment_date),status order by months ;

-- Understand Doctor and Room Performance

-- Compare the number of treatments handled by doctors.
select doctor_id,count(treatment_id) from treatments group by doctor_id;

-- doctor performance across treatment outcomes.
 select doctor_id,status,count(status)from treatments group by doctor_id,status order by doctor_id;

-- treatment duration across doctors.
select doctor_id,avg(treatment_duration_min) as avg_time from treatments group by doctor_id order by avg_time desc;

-- room usage across room types and equipment types.
SELECT 
    r.room_type,
    r.equipment_type,
    COUNT(t.treatment_id) AS treatment_usage
FROM rooms r
JOIN treatments t
    ON r.room_id = t.room_id
GROUP BY r.room_type, r.equipment_type
ORDER BY treatment_usage DESC;

-- treatment performance across rooms.
select r.room_id,count(t.treatment_id),avg(t.treatment_duration_min) from rooms r join treatments t on r.room_id=t.room_id group by(r.room_id);

-- Treatment and Appointment Problems

-- appointments requiring multiple treatment attempts.
select a.appointment_id,t.treatment_attempt from appointments a join treatments t on a.appointment_id=t.appointment_id  where t.treatment_attempt>1 ;

-- common problem statuses and patterns
select status,count(status) as count from treatments group by status order by count desc; 

-- waiting time for appointments with multiple treatment attempts.
SELECT 
    treatment_attempt,
    AVG(waiting_time_min) AS avg_waiting_time
FROM treatments
GROUP BY treatment_attempt
ORDER BY treatment_attempt;

-- city problem count
SELECT 
    p.city,
    t.status,
    COUNT(t.treatment_id) AS problem_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
WHERE t.status IN ('Cancelled', 'No-Show', 'Rescheduled')
GROUP BY p.city, t.status
ORDER BY problem_count DESC;


-- service types

SELECT 
    a.service_type,
    t.status,
    COUNT(t.treatment_id) AS problem_count
FROM appointments a
JOIN treatments t
    ON a.appointment_id = t.appointment_id
WHERE t.status IN ('Cancelled', 'No-Show', 'Rescheduled')
GROUP BY a.service_type, t.status
ORDER BY problem_count DESC;

-- whether priority level is associated with waiting time or treatment outcomes.

select a.priority,avg(t.waiting_time_min) as avg_time from appointments a join treatments t on a.appointment_id=t.appointment_id group by priority;

select a.priority,t.status,count(t.status) as count from appointments a join treatments t on a.appointment_id=t.appointment_id group by a.priority,t.status;

-- 4 additional qustions 
-- 1.Cancellation/No-show rate by city
SELECT 
    p.city,
    SUM(CASE WHEN t.status IN ('Cancelled', 'No-Show') THEN 1
            ELSE 0 END
    ) * 100.0 / COUNT(a.appointment_id) AS cancellation_no_show_rate
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
LEFT JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY p.city
ORDER BY cancellation_no_show_rate DESC;

-- 2.Cancellation/No-show rate by booking channel
SELECT 
    a.booking_channel,
    SUM(
        CASE WHEN t.status IN ('Cancelled', 'No-Show') THEN 1
            ELSE 0 END
    ) * 100.0 / COUNT(a.appointment_id) AS cancellation_no_show_rate
FROM appointments a
LEFT JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY a.booking_channel
ORDER BY cancellation_no_show_rate DESC;

-- Average waiting time by service type
SELECT 
    a.service_type,
    AVG(t.waiting_time_min) AS avg_waiting_time
FROM appointments a
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY a.service_type
ORDER BY avg_waiting_time DESC;
-- Doctor workload vs treatment value
SELECT 
    doctor_id,
    COUNT(treatment_id) AS treatment_count,
    SUM(treatment_cost) AS total_treatment_cost
FROM treatments
GROUP BY doctor_id
ORDER BY treatment_count DESC;

-- now we see by compairing with avg treatment cost.
SELECT 
    doctor_id,
    COUNT(treatment_id) AS treatment_count,
    SUM(treatment_cost) AS total_treatment_cost,
    AVG(treatment_cost) AS avg_treatment_cost
FROM treatments
GROUP BY doctor_id
ORDER BY avg_treatment_cost DESC;

/*
========================================================
              BUSINESS INSIGHTS
========================================================

1. PATIENT CONCENTRATION AND CANCELLATION PATTERNS
--------------------------------------------------------
Mumbai, Kochi, and Chennai have the highest patient
concentration and also show higher cancellation/no-show
rates.

Cancellation/No-show rates:
- Mumbai: 16.74%
- Kochi: 16.73%
- Chennai: 16.48%

Insight:
High-demand cities also show relatively higher
cancellation/no-show rates. These cities may require
greater attention to appointment confirmation and
reminder processes.


2. BOOKING CHANNEL AND APPOINTMENT RELIABILITY
--------------------------------------------------------
The App is the most-used booking channel.

Cancellation/No-show rates:
- Referral: 16.22%
- Website: 15.99%
- Phone: 15.49%
- Walk-in: 14.92%
- App: 14.40%

Insight:
Referral bookings have the highest cancellation/no-show
rate, while App bookings have the lowest. Stronger
confirmation and reminder processes could be considered
for referral bookings.


3. DOCTOR WORKLOAD DOES NOT NECESSARILY CORRESPOND
   TO TREATMENT VALUE
--------------------------------------------------------
D080:
- 66 treatments
- Total treatment cost: 123,694
- Average treatment cost: 1,874.15

D064:
- 45 treatments
- Total treatment cost: 122,025.76
- Average treatment cost: 2,711.68

Insight:
D080 handled the highest workload and generated the
highest total treatment value, while D064 generated
nearly the same total treatment value with 21 fewer
treatments.

This shows that treatment volume and treatment value
are not necessarily proportional.


4. APPOINTMENT DEMAND VARIES OVER TIME
--------------------------------------------------------
February 2025 had the highest number of appointments,
followed by October 2025.

Insight:
Appointment demand varies by month. Historical demand
patterns can help the hospital plan staffing, rooms,
and other resources during high-demand periods.


5. WAITING TIMES ARE CONSISTENT ACROSS SERVICE TYPES
--------------------------------------------------------
Average waiting times:
- Diagnostic Test: 15.95 minutes
- Consultation: 15.62 minutes
- Emergency Care: 15.55 minutes
- Procedure: 15.50 minutes
- Follow-up: 15.34 minutes

Insight:
Waiting times are relatively consistent across service
types, with less than one minute separating the highest
and lowest averages. No major service-specific waiting
time bottleneck was identified in the dataset.

========================================================
*/