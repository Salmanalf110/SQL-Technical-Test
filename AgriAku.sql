-- No 1: Who did not enroll in 2019?
SELECT
	name
FROM 
	student S
WHERE id  not in
	(
	SELECT STUDENT_ID 
	FROM enrollment e 
	WHERE enroll_dt LIKE '%19'
	);

-- No 2: Who had attendance below 75% and which course was it?
WITH main AS 
(SELECT 
	ca.student_id,
	ca.schedule_id,
	s.course_id,
	co.name course_name,
	st.name,
	count(ca.id) as total_attendance,
	length(replace(s.course_days,',',''))*(week(s.end_dt)-week(s.start_dt)) total_course_day
FROM course_attendance ca
	LEFT JOIN schedule s on ca.schedule_id = s.id
	LEFT JOIN student st on ca.schedule_id = st.id 
	LEFT JOIN course co on ca.schedule_id = co.id 
GROUP BY 1,2,3,4,5,7),

main2 AS 
(SELECT name, course_name, (total_attendance/total_course_day*100) attd_pctg
FROM main)

SELECT name,course_name
from main2
where attd_pctg<75;


-- No 3: Who had 100% attendance but ever failed the exam ? Breakdown per course.
WITH main AS 
(SELECT 
	ca.student_id,
	ca.schedule_id,
	s.course_id,
	co.name course_name,
	st.name,
	count(ca.id) as total_attendance,
	length(replace(s.course_days,',',''))*(week(s.end_dt)-week(s.start_dt)) total_course_day
FROM course_attendance ca
	LEFT JOIN schedule s on ca.schedule_id = s.id
	LEFT JOIN student st on ca.schedule_id = st.id 
	LEFT JOIN course co on ca.schedule_id = co.id 
GROUP BY 1,2,3,4,5,7),

main2 AS 
(SELECT student_id, name, course_name, (total_attendance/total_course_day*100) attd_pctg
FROM main),

main3 AS
(SELECT *
from main2
where attd_pctg=100)

select name, course_name
from main3
WHERE student_id in(
select distinct student_id
from exam_submission es 
left join exam e on es.exam_id = e.id
WHERE es.score<e.pass_threshold )


-- No 4: 4.	Who had attendance below 75% but passed the exam ? Breakdown per course.
WITH main AS 
(SELECT 
	ca.student_id,
	ca.schedule_id,
	s.course_id,
	co.name course_name,
	st.name,
	count(ca.id) as total_attendance,
	length(replace(s.course_days,',',''))*(week(s.end_dt)-week(s.start_dt)) total_course_day
FROM course_attendance ca
	LEFT JOIN schedule s on ca.schedule_id = s.id
	LEFT JOIN student st on ca.schedule_id = st.id 
	LEFT JOIN course co on ca.schedule_id = co.id 
GROUP BY 1,2,3,4,5,7),

main2 AS 
(SELECT student_id, name, course_name, (total_attendance/total_course_day*100) attd_pctg
FROM main),

main3 AS
(SELECT *
from main2
where attd_pctg>75)

select name,student_id, course_name
from main3
WHERE student_id in(
select student_id
from exam_submission es 
left join exam e on es.exam_id = e.id
WHERE es.score>e.pass_threshold)


-- No 5: Who did resit and passed and what course was it ? 
WITH resit AS
(SELECT es.student_id, e.course_id 
FROM exam_submission es
LEFT JOIN exam e 
	ON e.id = es.exam_id
WHERE es.score < e.pass_threshold 
ORDER BY 1)

SELECT s.name, c.name
from resit
JOIN student s ON s.id = resit.student_id
JOIN course c ON c.id = resit.course_id
GROUP BY 1,2
HAVING COUNT(*)=1


-- No.6 Who completely failed the test and what course was it ?
WITH resit AS
(SELECT es.student_id, e.course_id 
FROM exam_submission es
LEFT JOIN exam e 
	ON e.id = es.exam_id
WHERE es.score < e.pass_threshold 
ORDER BY 1)

SELECT s.name, c.name
from resit
JOIN student s ON s.id = resit.student_id
JOIN course c ON c.id = resit.course_id
GROUP BY 1,2
HAVING COUNT(*)>1

-- No.7 Rank students based on the highest average score during the academic year 19/20
with cte as
(SELECT s.name, MAX(score) max_score
FROM exam_submission es
JOIN student s ON es.student_id =s.id
JOIN exam e ON e.id = es.exam_id
JOIN course c ON c.id = e.course_id
WHERE student_id IN (
	SELECT student_id
	FROM enrollment e
	WHERE ACADEMIC_YEAR = '2019/2020')
GROUP BY 1,e.course_id)

SELECT 
	ROW_NUMBER() OVER(ORDER BY AVG(max_score)desc, name) as ranking,
	name as 'Student Name',
	AVG(max_score) as 'Average Score'
from cte
GROUP BY 2











